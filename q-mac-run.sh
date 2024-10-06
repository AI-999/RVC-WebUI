#!/bin/sh

if [ "$(uname)" = "Darwin" ]; then
  # macOS specific env:
  export PYTORCH_ENABLE_MPS_FALLBACK=1
  export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
elif [ "$(uname)" != "Linux" ]; then
  echo "Unsupported operating system."
  exit 1
fi

if [ -d ".venv" ]; then
  echo "Activate venv..."
  . .venv/bin/activate
else
  
  requirements_file="requirements-py311.txt"

  # Check if Python is installed
  if ! command -v python >/dev/null 2>&1; then
    echo "Python 3 not found. Attempting to install 3.8+..."
    exit 1
  else
    python_major_minor=$(python --version 2>&1 | awk '{print $2}' | cut -d. -f1-2)
    python_version_num=$(echo "$python_major_minor" | awk -F. '{print $1*100 + $2}')
    required_version_num=308  # 3.8对应的整数
    # 比较版本号,>=3.8，推荐3.11
    if [ "$python_version_num" -ge "$required_version_num" ]; then
      echo "Python version is: $python_major_minor ok."
    else
       echo "Please install Python 3.8++ manually."
       exit 1
    fi
  fi
  
  echo "Create venv..."
  python -m venv .venv
  . .venv/bin/activate

  # Check if required packages are installed and install them if not
  if [ -f "${requirements_file}" ]; then
    installed_packages=$(python -m pip freeze)
    while IFS= read -r package; do
      expr "${package}" : "^#.*" > /dev/null && continue
      package_name=$(echo "${package}" | sed 's/[<>=!].*//')
      if ! echo "${installed_packages}" | grep -q "${package_name}"; then
        echo "${package_name} not found. Attempting to install..."
        python -m pip install --upgrade "${package}"
      fi
    done < "${requirements_file}"
  else
    echo "${requirements_file} not found. Please ensure the requirements file with required packages exists."
    exit 1
  fi
fi

# Download models
#chmod +x tools/dlmodels.sh
#./tools/dlmodels.sh

if [ $? -ne 0 ]; then
  exit 1
fi

# Run the main script
python infer-web.py --pycmd python
