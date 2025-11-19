#!/bin/bash

# Check if the script is running on Linux
if [ "$(uname)" == "Linux" ]; then

    # Update package lists
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y git
    sudo apt-get install -y calibre
    sudo apt-get install -y espeak
    sudo apt-get install -y espeak-ng
    sudo apt-get install -y ffmpeg
    sudo apt-get install -y wget
    sudo apt-get install -y unzip

    # Check for and install pip if needed
    if ! command -v pip &> /dev/null; then
        sudo apt-get install -y python3-pip
    fi

    # Check for Python 3.10 or later and install if needed
    python_version=$(python3 --version 2>&1)
    if [[ ! "$python_version" =~ ^Python\ (3\.1[0-9]|3\.[2-9]\.|[4-9]\.) ]]; then
        sudo apt-get install python3.10
    fi

    # Check for Conda and install if needed
    if ! command -v conda &> /dev/null; then
        # Download and install Miniconda
        miniconda_installer="Miniconda3-latest-Linux-x86_64.sh"
        wget https://repo.anaconda.com/miniconda/$miniconda_installer
        bash $miniconda_installer -b -p ~/miniconda
        rm $miniconda_installer
        # Add Conda to PATH
        export PATH="$HOME/miniconda/bin:$PATH"
    fi

    # Create and activate a new Conda environment using Python 3.10
    conda create --name VoxNovel python=3.10
    # Add Conda to PATH
    export PATH="$HOME/miniconda/bin:$PATH"
    # Activate the base Conda environment
    source ~/miniconda/bin/activate
    conda init
    conda activate VoxNovel

    # Clone the VoxNovel repository (using temporary branch repository)
    #git clone https://github.com/DrewThomasson/VoxNovel.git
    git clone https://github.com/IEM-Regular-User/VoxNovel_ROCm.git
    
    # Navigate to the VoxNovel directory
    cd VoxNovel

    # Install ROCm Dependancies
    pip install --upgrade pip wheel
    wget https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4.2/torch-2.6.0%2Brocm6.4.2.git76481f7c-cp310-cp310-linux_x86_64.whl
    wget https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4.2/torchvision-0.21.0%2Brocm6.4.2.git4040d51f-cp310-cp310-linux_x86_64.whl
    wget https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4.2/torchaudio-2.6.0%2Brocm6.4.2.gitd8831425-cp310-cp310-linux_x86_64.whl
    wget https://repo.radeon.com/rocm/manylinux/rocm-rel-6.4.2/pytorch_triton_rocm-3.2.0%2Brocm6.4.2.git7e948ebf-cp310-cp310-linux_x86_64.whl
    pip install torch-2.6.0+rocm6.4.2.git76481f7c-cp310-cp310-linux_x86_64.whl \
            torchvision-0.21.0+rocm6.4.2.git4040d51f-cp310-cp310-linux_x86_64.whl \
            torchaudio-2.6.0+rocm6.4.2.gitd8831425-cp310-cp310-linux_x86_64.whl \
            pytorch_triton_rocm-3.2.0+rocm6.4.2.git7e948ebf-cp310-cp310-linux_x86_64.whl

    # Apply WSL2 Runtime Fix using Python method
    # Get PyTorch package path using Python
    torch_path=$(python -c "import torch, os; print(os.path.dirname(torch.__file__))")
    # Go to the 'lib' folder inside the PyTorch package
    cd "${torch_path}/lib/"
    # Remove the bundled ROCm runtime
    rm libhsa-runtime64.so*

    # Install necessary Python packages
    pip install styletts2 
    #pip install tts==0.21.3
    # This is the updated tts install pip cause the official is dead now sad face
    pip install pandas
    pip install coqui-tts
    pip install booknlp==1.0.7.1
    pip install bs4
    pip install -r Ubuntu_rocm_requirements.txt
    
    #Run test
    python3 -c "import torch; print('PyTorch', torch.__version__); print('ROCm available', torch.cuda.is_available()); \
    import sys; sys.exit(0 if torch.cuda.is_available() else 1)"
    
    pip install ebooklib==0.18
    pip install epub2txt==0.1.6
    pip install pygame==2.6.0
    pip install moviepy==1.0.3

    # Download the spaCy language model
    pip install spacy
    python -m spacy download en_core_web_sm


    # This will use the backup of the nltk files instead
    echo "Replacing the nltk folder with the nltk folder backup I Pulled from a docker image, just in case the nltk servers ever mess up."

    # Variables
    ZIP_URL="https://github.com/DrewThomasson/VoxNovel/blob/main/readme_files/nltk.zip?raw=true"
    TARGET_DIR="$HOME/miniconda/envs/VoxNovel/lib/python3.10/site-packages"
    TEMP_DIR=$(mktemp -d)
    
    # Download the zip file
    echo "Downloading zip file..."
    wget -q -O "$TEMP_DIR/nltk.zip" "$ZIP_URL"
    
    # Extract the zip file
    echo "Extracting zip file..."
    unzip -q "$TEMP_DIR/nltk.zip" -d "$TEMP_DIR"
    
    # Replace contents
    echo "Replacing contents..."
    rm -rf "$TARGET_DIR/nltk"
    mv "$TEMP_DIR/nltk" "$TARGET_DIR/nltk"
    
    # Clean up
    echo "Cleaning up..."
    rm -rf "$TEMP_DIR"
    
    echo "NLTK Files Replacement complete."










    # Create a Desktop Entry for the VoxNovel app
    echo "[Desktop Entry]
    Version=1.0
    Type=Application
    Name=VoxNovel
    Exec=$HOME/VoxNovel/shell_install_scripts/run/Ubuntu_run_voxnovel.sh
    Icon=$HOME/VoxNovel/readme_files/logo.jpeg
    Terminal=true
    " > $HOME/Desktop/VoxNovel.desktop
    cp $HOME/Desktop/VoxNovel.desktop ~/.local/share/applications
    
    # Make both Desktop Entries executable
    chmod +x $HOME/Desktop/VoxNovel.desktop
    chmod +x ~/.local/share/applications/VoxNovel.desktop
    # Make the Ubuntu voxnovel run script executable
    chmod +x $HOME/VoxNovel/shell_install_scripts/run/Ubuntu_run_voxnovel.sh
    # Update the application database
    sudo update-desktop-database

    # This part of the script will pre-download the tos_agreed.txt file so then you don't have to type yes in the terminal when downloading the coqio xtts_v2 model. 
    # Get the current user's home directory
    USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
    
    # Set the destination directory and file URL
    DEST_DIR="$USER_HOME/.local/share/tts/tts_models--multilingual--multi-dataset--xtts_v2"
    FILE_URL="https://github.com/DrewThomasson/VoxNovel/raw/main/readme_files/tos_agreed.txt"
    
    # Create the destination directory if it doesn't exist
    mkdir -p "$DEST_DIR"
    
    # Download the file to the destination directory
    curl -o "$DEST_DIR/tos_agreed.txt" "$FILE_URL"
    
    echo "File has been saved to $DEST_DIR/tos_agreed.txt"
    echo "The tos_agreed.txt file is so that you don't have to tell coqio tts yes when downloading the xtts_v2 model."
    
    echo "VoxNovel Install FINISHED! (You can close out of this window now)"

else
    echo "This script is intended to be run on Linux."
fi
