# Justfile for porting TensorFlow Lite model using micromamba

setup-env:
    #!/bin/bash
    mkdir -p micromamba
    curl -L https://micromamba.snakepit.net/api/micromamba/linux-64/latest | tar -xvj -C micromamba
    ./micromamba/bin/micromamba create -y -n iree-env python=3.12
    eval "$(./micromamba/bin/micromamba shell hook --shell bash)"
    source ~/.bashrc
    ./micromamba/bin/micromamba activate iree-env
    export PATH=~/bin:$PATH
    ./micromamba/bin/micromamba shell init --shell bash --root-prefix=~/.local/share/mamba
    source ~/.bashrc
    python -m pip install \
        --find-links https://iree.dev/pip-release-links.html \
        --upgrade \
        tensorflow
    python -m pip install \
        --find-links https://iree.dev/pip-release-links.html \
        --upgrade \
        iree-compiler==20240828.999 \
        iree-runtime==20240828.999 \
        iree-tools-tflite==20240828.999 \
        iree-tools-tf==20240828.999

convert-tf2-to-mlir model:
    iree-import-tf {{model}} -o model.mlir

convert-tflite-to-mlir model:
    iree-import-tflite {{model}} -o model.mlir
    @just compile-metal
    @just compile-vulkan

compile-metal:
    iree-compile --iree-input-type=tosa --iree-hal-target-backends=metal-spirv model.mlir -o model.metal.vmfb

compile-vulkan:
    iree-compile --iree-input-type=tosa --iree-hal-target-backends=vulkan-spirv model.mlir -o model.vulkan.vmfb

uninstall-iree:
  python -m pip uninstall \
    iree-base-compiler \
    iree-base-runtime \
    iree-compiler \
    iree-runtime \
    iree-tools-tflite
