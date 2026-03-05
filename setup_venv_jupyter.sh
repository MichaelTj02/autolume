#!/bin/bash
# Setup script for Autolume using uv - Jupyter/Vast.ai optimized
# This script creates a virtual environment and installs all dependencies
# Optimized for cloud GPU environments like Vast.ai

set -e  # Exit on error

echo "========================================="
echo "Autolume Virtual Environment Setup"
echo "For Vast.ai / Jupyter Terminal"
echo "========================================="
echo ""

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
    if ! command -v uv &> /dev/null; then
        echo "Error: Failed to install uv. Please install manually."
        exit 1
    fi
fi

echo "✓ uv is installed"
echo ""

# Set Python version
PYTHON_VERSION="3.10"

# Create virtual environment with Python 3.10
echo "Creating virtual environment with Python ${PYTHON_VERSION}..."
uv venv --python ${PYTHON_VERSION} .venv

echo "✓ Virtual environment created"
echo ""

# Activate virtual environment
echo "Activating virtual environment..."
source .venv/bin/activate

echo "✓ Virtual environment activated"
echo ""

# Upgrade pip
echo "Upgrading pip..."
uv pip install --upgrade pip

echo "✓ pip upgraded"
echo ""

# Install dependencies from requirements-training.txt (excludes optional packages that need system libs)
echo "Installing dependencies for training..."
echo "This may take several minutes, especially for PyTorch with CUDA support..."
echo "Note: Skipping ndi-python and pyaudio (require system libraries, not needed for training)"
echo ""

# Use requirements-training.txt which excludes ndi-python and pyaudio
# --index-strategy unsafe-best-match allows checking all indexes for best version matches
# This is needed because PyTorch index may not have all packages at exact versions
if [ -f requirements-training.txt ]; then
    uv pip install --index-strategy unsafe-best-match -r requirements-training.txt
else
    # Fallback: install from requirements.txt but skip problematic packages
    echo "Creating training requirements file..."
    grep -v "ndi-python\|pyaudio" requirements.txt > requirements-training.txt
    uv pip install --index-strategy unsafe-best-match -r requirements-training.txt
fi

echo ""
echo "✓ All dependencies installed"
echo ""

# Verify PyTorch installation and CUDA availability
echo "Verifying PyTorch installation..."
python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'Number of GPUs: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'  GPU {i}: {torch.cuda.get_device_name(i)}')
        print(f'    Memory: {torch.cuda.get_device_properties(i).total_memory / 1024**3:.2f} GB')
else:
    print('Warning: CUDA is not available. Make sure CUDA 12.8 is installed.')
"

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "IMPORTANT: In Jupyter terminal, activate the venv with:"
echo "  source .venv/bin/activate"
echo ""
echo "To run Autolume:"
echo "  python main.py"
echo ""
echo "To train a model:"
echo "  python train.py --outdir=./training-runs --cfg=stylegan2 --data=/path/to/dataset --gpus=1 --batch=4 --gamma=10.0 --resolution=(512,512)"
echo ""
