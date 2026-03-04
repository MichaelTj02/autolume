#!/bin/bash
# Setup script for Autolume using uv
# This script creates a virtual environment and installs all dependencies
# for running Autolume and training on a cloud GPU

set -e  # Exit on error

echo "========================================="
echo "Autolume Virtual Environment Setup"
echo "========================================="
echo ""

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "Error: uv is not installed."
    echo "Please install uv first:"
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
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

# Upgrade pip and install uv pip
echo "Upgrading pip..."
uv pip install --upgrade pip

echo "✓ pip upgraded"
echo ""

# Install dependencies from requirements.txt
echo "Installing dependencies from requirements.txt..."
echo "This may take several minutes, especially for PyTorch with CUDA support..."
echo ""

# Use uv pip to install from requirements.txt
# The --extra-index-url for PyTorch CUDA is already in requirements.txt
# uv pip will automatically handle the --extra-index-url directive in the file
uv pip install -r requirements.txt

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
else:
    print('Warning: CUDA is not available. Make sure CUDA 12.8 is installed.')
"

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "To activate the virtual environment in the future, run:"
echo "  source .venv/bin/activate"
echo ""
echo "To run Autolume:"
echo "  python main.py"
echo ""
echo "To train a model:"
echo "  python train.py [options]"
echo ""
echo "To deactivate the virtual environment:"
echo "  deactivate"
echo ""
