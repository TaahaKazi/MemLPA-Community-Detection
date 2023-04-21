#pragma once
#include "assert.h"
#include "stdio.h"
#include <algorithm>
#include <cuda.h>
#include <cuda_runtime.h>

#include "utils/logger.cuh"
#include "utils/rng.cuh"
#include "utils/timer.h"

#include <iostream>
#include <vector>
#include <ordered_map>
#include <random>
#include <cmath>
#include <bits/stdc++.h>

using namespace std;

/*! \brief File containing student code

students should only modify this file
*/

//  You can use this kernel defination
/*
__global__ void GMM(float *A, float *B, float *C, size_t Arow, size_t Acol, size_t Bcol){

}
*/

// Define cuda kernel here
// Define cuda kernel here
// Define cuda kernel here
// Define cuda kernel here
__global__ void kernel_MemLPA(ordered_map::device_ptr<float> mem, float *d_Adj, int iteration, int n_nodes, float *current_labels, float *d_label_history_0, float *d_label_history_1, float *d_label_history_2, float *mean_label_score, float *stddev_label_score)
{ 
    /* 
    mem stores the memory/scoreboard of the community labels for each node -- node->comm_label->score
    current_labels is the previous label for current node 
    mean_label_score & stddev_label_score track the mean & std dev of the scores of all communities for each node for the last iteration
    */
    int node = blockIdx.x * blockDim.x + threadIdx.x; // assuming number of threads = no of nodes
    //int n_nodes = d_Adj.size();

    if(node < n_nodes):
    {
        ordered_map<int, float> community_labels = mem[node]; // scoreboard for the node

        // change this to adjacency list for faster access
        for (int neighbor = 0; neighbor < n_nodes; neighbor++)
        {
            float edge = d_Adj[node][neighbor];
            if (edge != 0)
            {
                community_labels[current_labels[neighbor]] += edge; // update scoreboard
            }
        }
        
        // Code to find max scored label and assign it to labels vector
        int max_key = -1;
        float max_value = 0;
        
        float M2 = 0;
        float delta;
        float rolling_mean = 0;
        int n = 0;
        flag_delete = 0; // turns to 1 if any community label has to be deleted
        del_key = -1; //init
        for (auto& kv : community_labels)
        {
            if (iteration!=1 && (kv.second < (mean_label_score[node]-stddev_label_score[node]))) // more than one std-dev away from mean, in the negative direction
            {
                if(flag_delete==1)
                {
                    community_labels.erase(del_key);
                }
                flag_delete = 1;
                del_key = kv.first;
                continue;
            }

            delta = kv.second - rolling_mean;
            rolling_mean += delta / (n + 1);
            M2 += delta * (kv.second - rolling_mean); // finding mean & std dev on a rolling basis
            n++; // counts no of community labels in the particular node's memory/scoreboard.
           
            if (kv.second > max_value)
            {
                max_key = kv.first;
                max_value = kv.second;
            }
        }
        if(flag_delete==1)
        {
            community_labels.erase(del_key);
        }
        current_labels[node] = max_key;
        mean_label_score[node] = rolling_mean;
        stddev_label_score[node] = sqrtf(M2 / (n));
        
        switch(iteration % 3) {
            case 0:
                d_label_history_0[node] = current_labels[node]// edit d_label_history_0
                break;
            case 1:
                d_label_history_1[node] = current_labels[node]// edit d_label_history_1
                break;
            default:
                d_label_history_2[node] = current_labels[node]// edit d_label_history_2
        }
    }
}

int main()
{
    const int N = 100;
    const int threadsPerBlock = 256;
    const int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    float* a, * b, * c, *d;
    float* d_a, * d_b, * d_c, *d_d;

    // Allocate memory on the host
    a = (float*)malloc(N * sizeof(float));
    b = (float*)malloc(N * sizeof(float));
    c = (float*)malloc(N * sizeof(float));
    d = (float*)malloc(N * sizeof(float));

    // Allocate memory on the device
    cudaMalloc(&d_a, N * sizeof(float));
    cudaMalloc(&d_b, N * sizeof(float));
    cudaMalloc(&d_c, N * sizeof(float));
    cudaMalloc(&d_d, N * sizeof(float));

    // Initialize arrays a and b
    for (int i = 0; i < N; i++) {
        a[i] = i;
        b[i] = i;
        c[i] = i;
    }

    // raw pointer to device memory
    float* raw_ptr;
    cudaMalloc((void**)&raw_ptr, N * sizeof(float));

    // wrap raw pointer with a device_ptr
    thrust::device_ptr<float> dev_ptr(raw_ptr);

    // Copy arrays a and b to the device
    cudaMemcpy(d_a, a, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_c, c, N * sizeof(float), cudaMemcpyHostToDevice);

    // Perform vector addition on the device
    vecAdd << <blocksPerGrid, threadsPerBlock >> > (d_a, d_b, d_c, d_d,N, dev_ptr);

    float sum = thrust::reduce(dev_ptr, dev_ptr + N, (float)0);
    printf("\n%f\n", sum);
    // Copy the result back to the host
    cudaMemcpy(d, d_d, N * sizeof(float), cudaMemcpyDeviceToHost);
    for (int i = 0; i < N; i++) {
        printf("%f\t", d[i]);
    }


    /*
    int flag = 1;
    // Verify the result
    for (int i = 0; i < N; i++) {
        if (c[i] != a[i] + b[i]) {
            printf("Error: c[%d] = %f, expected %f\n", i, c[i], a[i] + b[i]);
            flag = 0;
            break;
        }
    }
    printf("HELLO\n");
    printf("%f\n",c[0]);
    printf("%f\n", c[77]);
    printf("%f\n", c[9999999]);
    printf("%d", flag);
    */


    // Free memory
    free(a);
    free(b);
    free(c);
    free(d);
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
    cudaFree(d_d);

    return 0;
}
////////////////////////////////////////////////// 4/20/2023 5:47 PM 
/*
void BasicGMM() //size_t matArow, size_t matAcol, size_t matBrow, size_t matBcol, float *hostA, float *hostB, float *hostC)
{
  // &Adj points to adjcancy metrix on the host memory
  cudaMalloc((void**)&d_Adj,n*m*sizeof(float)); // d_Adj is pointer to device Adjacency matrix
  cudaMemcpy(&d_Adj,&Adj,n*m*sizeof(float),cudaMemcpyHostToDevice);





  // cout<<matArow<<endl;
  // cout<<hostA<<endl;
  if (matAcol != matBrow)
  {
    Log(critical, "Incorrect matrix configuration");
    return;
  }
  // device memory pointers
  float *deviceA = nullptr, *deviceB = nullptr, *deviceC = nullptr;
  size_t aSz = matArow * matAcol;
  size_t bSz = matBrow * matBcol;
  size_t cSz = matArow * matBcol;

  //////////////////////////////////////////
  // Allocate GPU Memory
  //////////////////////////////////////////
  Timer t;
  Log(debug, "Allocating GPU memory");
  // Fill this part
  // Fill this part
  // Fill this part
  // Fill this part
  // Fill this part
  cudaMalloc((void**)&deviceA, aSz * sizeof(float));
  cudaMalloc((void**)&deviceB, bSz * sizeof(float));
  cudaMalloc((void**)&deviceC, cSz * sizeof(float));

  double seconds = t.elapsed();
  Log(debug, "done... %f sec\n\n", seconds);

  //////////////////////////////////////////
  // Copy Host Data to GPU
  //////////////////////////////////////////
  Log(debug, "Copying host memory to the GPU");
  t.reset();
  // Fill this part
  // Fill this part
  // Fill this part
  // Fill this part
  cudaMemcpy(deviceA, hostA, aSz * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(deviceB, hostB, bSz * sizeof(float), cudaMemcpyHostToDevice);
  CUDA_RUNTIME(cudaMalloc((void **)&deviceC, cSz * sizeof(float)));
  seconds = t.elapsed();
  Log(debug, "done... %f sec\n\n", seconds);

  //////////////////////////////////////////
  // GPU M-M multiplication computation
  //////////////////////////////////////////
  Log(debug, "Performing GPU Matrix-Multiplication");
  t.reset();

  // Fill this part; call the kernel here (Remember: <<< >>>)
  // Fill this part; call the kernel here (Remember: <<< >>>)
  // Fill this part; call the kernel here (Remember: <<< >>>)
  // Fill this part; call the kernel here (Remember: <<< >>>)
  // Fill this part; call the kernel here (Remember: <<< >>>)
  // referenced https://github.com/lzhengchun/matrix-cuda/blob/master/matrix_cuda.cu for understanding
  int block_size = 16;
  int rows = (matArow + block_size - 1) / block_size;
  int cols = (matBcol + block_size - 1) / block_size;
  dim3 dimGrid(cols, rows);
  dim3 dimBlock(block_size, block_size);
  kernel_MemLPA<<<dimBlock, dimGrid>>>(deviceA, deviceB, deviceC, matArow, matAcol, matBcol);

  CUDA_RUNTIME(cudaDeviceSynchronize());
  seconds = t.elapsed();
  Log(debug, "done... %f sec\n\n", seconds);

  //////////////////////////////////////////
  // Copy GPU Data to Host
  //////////////////////////////////////////
  Log(debug, "Copying GPU memory to the host");
  t.reset();
  // Let me do this part for you
  CUDA_RUNTIME(cudaMemcpy(hostC, deviceC, cSz * sizeof(float), cudaMemcpyDeviceToHost));
  seconds = t.elapsed();
  Log(debug, "done... %f sec\n\n", seconds);
  for (int i = 0; i < matArow; i++) {
        for (int j = 0; j < matBcol; j++) {
            cout<<hostC[(i * matBcol) + j];
        }
    }

  //////////////////////////////////////////
  // Delete GPU memory
  //////////////////////////////////////////
  Log(debug, "Deleting GPU memory");
  t.reset();
  // Let me do this part for you
  CUDA_RUNTIME(cudaFree(deviceA));
  CUDA_RUNTIME(cudaFree(deviceB));
  CUDA_RUNTIME(cudaFree(deviceC));
  seconds = t.elapsed();
  Log(debug, "done... %f sec\n\n", seconds);
}*/