#include <stdio.h>
#include <cuda.h>
#include <iostream>
#include <vector>
#include <unordered_map>
#include <random>
#include <cmath>

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <thrust/copy.h>
#include <thrust/fill.h>
#include <thrust/sequence.h>

using namespace std;


__global__ void vecAdd(float* a, float* b, float* c, float* d, int n, thrust::device_ptr<float> devptr)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) 
    {
        if (a[i] == b[i])
        { 
            if (b[i] == c[i])
            {
                d[i] = 0;
                devptr[i] = 0;
            }
            else
            { 
                d[i] = 1;
                devptr[i] = 1;
            }
        }
        else
        { 
            d[i] = 1;
            devptr[i] = 1;
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
#include <stdio.h>
#include <cuda.h>
#include <iostream>
#include <vector>
#include <unordered_map>
#include <random>
#include <cmath>

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <thrust/copy.h>
#include <thrust/fill.h>
#include <thrust/sequence.h>

using namespace std;


__global__ void vecAdd(float* a, float* b, float* c, float* d, int n, thrust::device_ptr<float> devptr)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) 
    {
        if (a[i] == b[i])
        { 
            if (b[i] == c[i])
            {
                d[i] = 0;
                devptr[i] = 0;
            }
            else
            { 
                d[i] = 1;
                devptr[i] = 1;
            }
        }
        else
        { 
            d[i] = 1;
            devptr[i] = 1;
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
