/*
 *  Copyright 2020 Patrick Stotko
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include <iostream>
#include <thrust/copy.h>
#include <thrust/reduce.h>
#include <thrust/sequence.h>

#include <stdgpu/iterator.h>        // device_begin, device_end
#include <stdgpu/memory.h>          // createDeviceArray, destroyDeviceArray
#include <stdgpu/platform.h>        // STDGPU_HOST_DEVICE
#include <stdgpu/unordered_map.cuh> // stdgpu::unordered_map


__global__ void
insert_neighbors( float* a, float* b, float* d,const stdgpu::index_t n, stdgpu::unordered_map<int, stdgpu::unordered_map<int, int>> map, stdgpu::vector<stdgpu::unordered_map<int, int>> vec, stdgpu::unordered_map<int, int> my_map_1)
{
    stdgpu::index_t i = static_cast<stdgpu::index_t>(blockIdx.x * blockDim.x + threadIdx.x);

    if (i > n)
        return;
    // matrix size is 3 X 3; hence value of N was 3
    for (int itr = i*n; itr < i*n + n; itr++) {
        b[itr] = a[itr] * 2;
    }
    vec.at(i).emplace(0, 1);
    if (i==0)
    {
        my_map_1.emplace(0,1);
        int val = my_map_1.contains(0);
        d[i] = val;
    }
    //int val =  vec.at(i).contains(0);
    //d[i] = val;
    //stdgpu::unordered_map< int,int> ::iterator it = vec.at(i).find(0);


    //d[i] = it->second;
    
    // Defining a local map 
    // stdgpu::unordered_map<int, int> single_map_1 = stdgpu::unordered_map<int, int>::createDeviceObject(2);

    // Inserting values

}

int
main()
{
    //
    // EXAMPLE DESCRIPTION
    // -------------------
    // This example demonstrates how stdgpu::unordered_map is used to compute a duplicate-free set of numbers.
    //
    const int N = 9; // 9 because we are building a 3 X 3 matrix
    
    float* a, * b, * c, *d;
    float* d_a, * d_b, *d_d;

    


    // Allocate memory on the host
    a = (float*)malloc(N * sizeof(float));
    b = (float*)malloc(N * sizeof(float));
    c = (float*)malloc(N * sizeof(float));
    d = (float*)malloc(3 * sizeof(float));

    // Allocate memory on the device
    cudaMalloc(&d_a, N * sizeof(float));
    cudaMalloc(&d_b, N * sizeof(float));
    cudaMalloc(&d_d, 3 * sizeof(float));

    // Initialize arrays a and b
    for (int i = 0; i < N; i++) {
        a[i] = i;
        b[i] = 0;
    }
    for (int i = 0; i < 3; i++) {
        d[i] = 100;
    }

    stdgpu::vector<stdgpu::unordered_map<int, int>> vec = stdgpu::vector<stdgpu::unordered_map<int, int>>::createDeviceObject(3);


    // Copy arrays a and b to the device
    cudaMemcpy(d_a, a, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_d, d, 3 * sizeof(float), cudaMemcpyHostToDevice);

    const stdgpu::index_t n = 3; // 3 is the number of nodes

    //Defining an unordered map which contains an unordered map; henceforth referred to as unordered_square
    stdgpu::unordered_map<int, stdgpu::unordered_map<int, int>> my_map = 
        stdgpu::unordered_map<int, stdgpu::unordered_map<int, int>>::createDeviceObject(n);
    
    stdgpu::unordered_map<int, int> my_map_1 =  stdgpu::unordered_map<int, int>::createDeviceObject(n);
    
    //std::cout<< my_map_1 << std::endl;
    /*
    //Defining an unordered map, which will be inserted in the unordered_square
    stdgpu::unordered_map<int, int> single_map_1 = stdgpu::unordered_map<int, int>::createDeviceObject(2);
    
    // syntax for emplace(insertion) :first arg is key and second arg is value  
    single_map_1.emplace(0,1);
    single_map_1.emplace(1,22);

    stdgpu::unordered_map<int, int> single_map_2 = stdgpu::unordered_map<int, int>::createDeviceObject(2);
    
    // syntax for emplace(insertion) :first arg is key and second arg is value  
    single_map_2.emplace(0,99);
    single_map_2.emplace(1,33);

    my_map.emplace(0, single_map_1);
    my_map.emplace(1, single_map_2);


    */
    stdgpu::index_t threads = 32;
    stdgpu::index_t blocks = (n + threads - 1) / threads;
    insert_neighbors<<<static_cast<unsigned int>(blocks), static_cast<unsigned int>(threads)>>>(d_a, d_b, d_d,3, my_map, vec, my_map_1);
    cudaDeviceSynchronize();
    cudaMemcpy(c, d_b, N * sizeof(float), cudaMemcpyDeviceToHost);
    /*
    for (int i = 0; i < N; i++) {
        printf("%f\t", c[i]);
    }
    */
    printf("\n");
    cudaMemcpy(d, d_d, 3 * sizeof(float), cudaMemcpyDeviceToHost);
    for (int i = 0; i < 3; i++) {
        printf("%f\t", d[i]);
    }
    printf("\n");


    stdgpu::unordered_map<int, stdgpu::unordered_map<int, int>>::destroyDeviceObject(my_map);
}
