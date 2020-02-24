#include "LifegameField.h"
#include <random>
#include <iostream>
#include<cuda_runtime.h>
#include<opencv2/cudev.hpp>

__global__ void CorrectFieldKernel(cv::cudev::GlobPtrSz<uchar> field, cv::cudev::GlobPtrSz<uchar> buf);

__global__ void AdvanceGenKernel(cv::cudev::GlobPtrSz<uchar> field, cv::cudev::GlobPtrSz<uchar> buf, unsigned int gen);


LifegameField::LifegameField(int row, int col)
{
  cv::Mat tmp(cv::Size(col+2, row+2), CV_8UC1);

  cudaMallocManaged(&managedField, tmp.rows*tmp.cols*tmp.channels());
  cudaMallocManaged(&managedBuf, tmp.rows*tmp.cols*tmp.channels());

  int w = tmp.cols;
  int h = tmp.rows;

  cpuField = cv::Mat(cv::Size(w,h), CV_8UC1, managedField);
  gpuField = cv::cuda::GpuMat(cv::Size(w,h), CV_8UC1, managedField);

  cpuBuf = cv::Mat(cv::Size(w,h), CV_8UC1, managedBuf);
  gpuBuf = cv::cuda::GpuMat(cv::Size(w,h), CV_8UC1, managedBuf);

  memcpy(managedField, tmp.data, w*h);
  memcpy(managedBuf, tmp.data, w*h);

  RandomInit();
  CorrectField();
}

LifegameField::~LifegameField()
{
  cudaFree(managedBuf);
  cudaFree(managedField);
}

unsigned int LifegameField::AdvanceGen()
{
  gen ++;
  //  RandomInit();
  
  cv::cudev::GlobPtrSz<uchar> pField = 
    cv::cudev::globPtr(gpuField.ptr(0), gpuField.step, gpuField.rows, gpuField.cols * gpuField.channels());
  cv::cudev::GlobPtrSz<uchar> pBuf = 
    cv::cudev::globPtr(gpuBuf.ptr(0), gpuBuf.step, gpuBuf.rows, gpuBuf.cols * gpuBuf.channels()); 
  const dim3 block(32, 8);
  const dim3 grid(cv::cudev::divUp(gpuField.cols, block.x), cv::cudev::divUp(gpuField.rows, block.y));
  AdvanceGenKernel<<<grid, block>>>(pField, pBuf, gen);
  cudaDeviceSynchronize();
  memcpy(managedField, managedBuf, gpuField.rows* gpuField.cols);   
  CorrectField();
  return gen;
}


void LifegameField::CorrectField()
{
  cv::cudev::GlobPtrSz<uchar> pField = 
    cv::cudev::globPtr(gpuField.ptr(0), gpuField.step, gpuField.rows, gpuField.cols * gpuField.channels());
  cv::cudev::GlobPtrSz<uchar> pBuf = 
    cv::cudev::globPtr(gpuBuf.ptr(0), gpuBuf.step, gpuBuf.rows, gpuBuf.cols * gpuBuf.channels()); 
  const dim3 block(32, 8);
  const dim3 grid(cv::cudev::divUp(gpuField.cols, block.x), cv::cudev::divUp(gpuField.rows, block.y));
  CorrectFieldKernel<<<grid, block>>>(pField, pBuf);
  cudaDeviceSynchronize();
  memcpy(managedField, managedBuf, gpuField.rows* gpuField.cols);
}

void LifegameField::RandomInit()
{
  std::mt19937 mt{std::random_device{}()};
  std::uniform_int_distribution<unsigned int> dist(0,2);

  for(int c = 1; c < cpuField.cols-1; c ++){
    for(int r = 1; r < cpuField.rows-1; r ++){
      unsigned int v = dist(mt);
      if(v == 0){
	cpuField.at<unsigned char>(r,c) = 1;
      }
      else{
	cpuField.at<unsigned char>(r,c) = 0;
      }
    }
  }
}



__global__ void CorrectFieldKernel(cv::cudev::GlobPtrSz<uchar> field, cv::cudev::GlobPtrSz<uchar> buf)
{
  const int c = blockDim.x * blockIdx.x + threadIdx.x;
  const int r = blockDim.y * blockIdx.y + threadIdx.y;

  int cmax = field.cols - 1;
  int rmax = field.rows - 1;

  if(c >= field.cols || r >= field.rows){
    return;
  }

  if(c == 0 && r == 0){
    buf.data[r * field.step + c] = field.data[(rmax-1) * field.step + (cmax-1)];
    return;
  }
  
  if(c == 0 && r == rmax){
    buf.data[r * field.step + c] = field.data[(1) * field.step + (cmax-1)];
    return;
  }

  if(c == cmax && r == 0){
    buf.data[r * field.step + c] = field.data[(rmax-1) * field.step + (1)];
    return;
  }
  
  if(c == cmax && r == 0){
    buf.data[r * field.step + c] = field.data[(1) * field.step + (1)];
    return;
  }

  if(c == 0){
    buf.data[r * field.step + c] = field.data[(r) * field.step + (cmax-1)];
    return;
  }

  if(c == cmax){
    buf.data[r * field.step + c] = field.data[(r) * field.step + (1)];
    return;
  }

  if(r == 0){
    buf.data[r * field.step + c] = field.data[(rmax-1) * field.step + (c)];
    return;
  }

  if(r == rmax){
    buf.data[r * field.step + c] = field.data[(1) * field.step + (c)];
    return;
  }
  
  buf.data[r * field.step + c] = field.data[r * field.step + c]; 

}

__global__ void AdvanceGenKernel(cv::cudev::GlobPtrSz<uchar> field, cv::cudev::GlobPtrSz<uchar> buf, unsigned


				 int gen)
{
  const int c = blockDim.x * blockIdx.x + threadIdx.x;
  const int r = blockDim.y * blockIdx.y + threadIdx.y;

  int cmax = field.cols - 1;
  int rmax = field.rows - 1;

  if(c <= 0 || c >= cmax || r <= 0 || r >= rmax){
    return;
  }

  int center = field.data[(r) * field.step + (c)];

  int neighbor = 0;
  neighbor += field.data[(r-1) * field.step + (c-1)];
  neighbor += field.data[(r-1) * field.step + (c)];
  neighbor += field.data[(r-1) * field.step + (c+1)];
  neighbor += field.data[(r) * field.step + (c-1)];
  neighbor += field.data[(r) * field.step + (c+1)];
  neighbor += field.data[(r+1) * field.step + (c-1)];
  neighbor += field.data[(r+1) * field.step + (c)];
  neighbor += field.data[(r+1) * field.step + (c+1)];

  //birth
  if(center == 0 && ( neighbor == 3 || neighbor == 6)){
    buf.data[(r) * field.step + (c)] = 1;
    return;
  }

  if(center == 0){
    buf.data[(r) * field.step + (c)] = 0;
    return;
  }

  //center == 1
  //survival
  if(neighbor == 2 || neighbor == 3){
    buf.data[(r) * field.step + (c)] = 1;
    return;
  }
  
  //underpopulation
  //overpopulation
  buf.data[(r) * field.step + (c)] = 0;
  return;
}
