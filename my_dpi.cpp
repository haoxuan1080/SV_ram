#include <iostream>
#include "svdpi.h"

using namespace std;

extern "C" void test_bench_helper(long long int time, svLogic* hold_clk) {
    if (time > 10000) {
    	*hold_clk = 1;
	cout<<"holding clock from c++ at time"<<time<<endl;
    }
    else {
    	*hold_clk = 0;
    }
}
