#pragma once

#include<opencv2/opencv.hpp>
#include<memory>
#include"LifegameField.h"

class Lifegame
{
 protected:
  
  std::unique_ptr<LifegameField> field;
  unsigned int gen = 0;
  
 public:
  Lifegame(int row, int col);
  ~Lifegame();
  
  cv::Mat GetFieldImage();
  
  unsigned int AdvanceGen();
  unsigned int CurrGen();
};
