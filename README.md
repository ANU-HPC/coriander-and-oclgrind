
This repository was built to illustrate how [Coriander](https://github.com/hughperkins/coriander) and [Oclgrind](https://github.com/jrprice/Oclgrind) can be used together.
Unfortunately, the devil is in the details, -- the set-up is painful -- since it requires both libraries to be dynamically linked against the same version of LLVM to operate to avoid the following error:

    error "'phi-node-folding-threshold' registered more than once"

This repository uses Docker to outline the build steps I used to get these two awesome tools to play nice together.

# Dependencies

* [nvidia-docker2](https://github.com/NVIDIA/nvidia-docker)
* nvidia-container-runtime

# Precanned

You can avoid building the project by using my prebuilt image.
This is done with the following command:

    docker run --rm -it --runtime=nvidia beaujoh/coriander-and-oclgrind:1.0

If you are feeling like living in the old school, you can build and run directly -- this is outlined in the remainder of the README.

# Build

    docker build -t coriander-and-oclgrind .

# Run

    docker run --rm -it --runtime=nvidia coriander-and-oclgrind /bin/bash
    make test

