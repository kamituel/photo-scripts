# Add this to your .profile or .bashrc:
# . $HOME/photo-scripts/photo-scripts.sh
# (assuming $HOME/photo-scripts is the location of this file)

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH=$PATH:"$SELF_DIR"
