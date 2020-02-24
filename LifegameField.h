#pragma once

#include<opencv2/opencv.hpp>


class LifegameField
{
 protected:
  unsigned char* managedField = nullptr;
  cv::Mat cpuField;
  cv::cuda::GpuMat gpuField;

  unsigned char* managedBuf = nullptr;
  cv::Mat cpuBuf;
  cv::cuda::GpuMat gpuBuf;
  
  unsigned int gen = 0;

 public:
  LifegameField(int row, int col);
  ~LifegameField();
  cv::Mat GetField(){
    return cpuField;
  }

  unsigned int AdvanceGen();
  unsigned int CurrGen(){
    return gen;
  }

 protected:
  void RandomInit();
  void CorrectField();
  
};
