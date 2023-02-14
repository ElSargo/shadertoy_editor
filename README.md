# Shadertoy editor
Use a native editor to edit and run shaders on shadertoy.com

## Usage
The script will spawn a selenium firefox windows and whatch for changes to shader.glsl  
When it detects saved changes it will insert the contents of the file into the buffer and recompile the shader.

## Installation
clone the repo and run the main.py with python.  

```fish
git clone https://github.com/ElSargo/shadertoy_editor/new/main?readme=1  
cd shader_toy editor
python main.py
```

# Dependencies 
Make sure you have these installed:
* python3.10 or later
* selenium
* firefox  


For debian based distros
```fish
sudo apt install python3
pip install selenium
sudo apt install firefox
```
# Nix shell
There is a shell.nix that will pull dependencies to a temporary shell and run the program
```fish
nix-shell
```
