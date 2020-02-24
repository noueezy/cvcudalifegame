#include "Lifegame.h"
#include <random>

Lifegame::Lifegame(int row, int col)
{
  field.reset(new LifegameField(row, col));  
}

Lifegame::~Lifegame()
{
}

cv::Mat Lifegame::GetFieldImage()
{
  cv::Mat fieldmat = field->GetField();
  int fc = fieldmat.cols-2;
  int fr = fieldmat.rows-2;
  int cellSize = 4;
  int lineWidth = 1;
  int width = (cellSize + lineWidth) * fc + lineWidth;
  int height = (cellSize + lineWidth) * fr + lineWidth;
  cv::Mat img = cv::Mat::zeros(height, width, CV_8UC3);
  cv::Scalar lineColor(40,40,40);

  for(int c = 1; c <= fc; c ++){
    for(int r = 1; r <= fr; r ++){
      int rectSize = cellSize + lineWidth;
      cv::Point p1(rectSize*(c-1), rectSize*(r-1));
      cv::Point p2(rectSize*c, rectSize*r);
      if(fieldmat.at<unsigned char>(r,c) == 1){
	cv::rectangle(img, p1, p2, cv::Scalar(0,255,0),-1);
      }
      else{
	cv::rectangle(img, p1, p2, cv::Scalar(0,0,0), -1);
      }     
    }
  }
  
  for(int i = 0; i <= fc; i ++){
    cv::Point p1(i*(cellSize+lineWidth), 0);
    cv::Point p2(i*(cellSize+lineWidth), height-1);
    cv::line(img, p1, p2, lineColor, 1);
  }

  for(int i = 0; i <= fr; i ++){
    cv::Point p1(0, i*(cellSize+lineWidth));
    cv::Point p2(width-1, i*(cellSize+lineWidth));
    cv::line(img, p1, p2, lineColor, 1);
  }
  
  return img;
}

unsigned int Lifegame::AdvanceGen()
{
  return field->AdvanceGen();
}

unsigned int Lifegame::CurrGen()
{
  return field->CurrGen();
}

