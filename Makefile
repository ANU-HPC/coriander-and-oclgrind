
all: gaussian_cuda gaussian_opencl gaussian_hand_opencl

gaussian_cuda: gaussian_cuda_version/gaussian.cu
	nvcc gaussian_cuda_version/gaussian.cu -o gaussian_cuda

gaussian_opencl: ./gaussian_cuda_version/gaussian.cu
	${COCL} ./gaussian_cuda_version/gaussian.cu -o gaussian_opencl

gaussian_hand_opencl: gaussian_opencl_version/*.cpp
	g++ gaussian_opencl_version/*.cpp -I./gaussian_opencl_version/ -lOpenCL -o gaussian_hand_opencl

test: gaussian_opencl
	${OCLGRIND_BIN} --aiwc ./gaussian_opencl ./matrix4.txt

clean:
	rm -f *.ll *.o gaussian_cuda gaussian_opencl gaussian_hand_opencl aiwc_*
