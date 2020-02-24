#include <iostream>
#include <csignal>
#include <unistd.h>
#include <opencv2/opencv.hpp>

#include "Lifegame.h"

static int breakFlg = false;

void signalHandler(int sig)
{
  switch(sig){
  case SIGINT:
    breakFlg = true;
    break;
  default:
    break;
  }
}

int main()
{
  //signal handler setting
  if(signal(SIGINT, signalHandler) == SIG_ERR){
    std::cout << "Cannot catch SIGINT" << std::endl;
    return -1;
  }

  Lifegame lifegame(130, 200);
  
  while(1){
    if(breakFlg){
      std::cout << "END."<< std::endl;
      break;
    }
    std::cout << "GEN: " << lifegame.CurrGen()  << std::endl;

    cv::Mat img = lifegame.GetFieldImage();
    cv::imshow("Lifegame", img);
    cv::waitKey(1);

    lifegame.AdvanceGen();
  }
  

  return 0;
}
