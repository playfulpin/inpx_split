#

## Project Overview
**inpx_split** is a set of shell scripts designed to process large INPX
files from Flibusta or similar sources.  
The project splits INPX archives into separate variants (`FB2` and `USR`),
counts books, updates headers, and generates clean output files for further
processing.

The project is cross-platform and works on both Windows (via WSL2) and Unix
systems. It is designed to be **modular, restartable, and robust** for batch
operations.

---

## Project Structure

InpxSolutions/
├── bin/ # Executables or runnable scripts
│ ├── inpx_splitter.sh
│ └── progress_bar.sh
├── lib/ # Shared functions & configuration
│ ├── config.sh
│ └── functions.sh
├── data/ # Input INPX files
├── log/ # Log files
└── README.md


---

## Requirements

- Bash 5+  
- Utilities: `7z`, `unzip`, `awk`, `fzf`, `figlet`  
- Optional: `bc` for statistics  
- Linux/WSL2 or Unix-compatible environment  

---

## Setup

1. Clone or copy the project into your development folder:
   ```bash
   ln -s /mnt/c/Development ~/DEV
   cd ~/DEV
   git clone <repo-url> InpxSolutions

---
Script Logic for bin/inpx_splitter.sh

Purpose: Split a full INPX file into two separate INPX files: FB2 and USR variants.
Steps:

Source config.sh and progress_bar.sh.
Parse CLI arguments (--debug, --help).
Change directory to the input folder (data/ by default).
Select an input INPX file interactively using fzf.
Create a temporary folder for processing files.
Generate temporary "keep lists" for FB2 and USR variants.
Use 7z to extract and filter files according to variant patterns:
FB2: *.info + *fb2-*.inp
USR: *.info + *usr-*.inp
Count the number of books in each variant by iterating over .inp files.
Update the INPX archive header with book counts and archive version info.
Clean up all temporary files and return to the folder where the script was started.
Print final messages including book counts and completion banner (figlet).
Notes:
Restartable at any point.
Debug mode prints additional logs.

---

bin/progress_bar.sh
Purpose: Display a dynamic progress bar with spinner and ETA for long-running loops.
Functions:
spinner – Returns a rotating character for visual feedback.
eta_time – Calculates estimated time remaining in MM:SS format.
progress_bar – Prints the progress bar with percentage, spinner, and ETA.
Usage: Called internally by inpx_splitter.sh when counting .inp files.
Notes: Handles initialization of timer, terminal width, and full completion formatting.
lib/config.sh
Purpose: Define and preserve the project folder structure.
Logic:
Sets PROJECT_ROOT automatically (resolving symbolic link ~/DEV/InpxSolutions).
Defines core folders: bin, lib, data, output, log.
Creates missing folders automatically (mkdir -p).
Sets LOG_FILE for script-specific logging.
Provides helper logging functions: log, log_info, log_warn, log_error.
Exports environment variables for use in child scripts.
lib/functions.sh
Purpose: (Optional) Place for shared reusable functions in future scripts.
Current usage: Could include file utilities, INPX operations, or batch helpers.

-------------

## Workflow Diagram

sql
Copy code
   +----------------+
   |  Input INPX    |
   |  (data/)       |
   +--------+-------+
            |
            v
   +----------------+
   |  Select file   |
   |  (fzf)         |
   +--------+-------+
            |
            v
   +----------------+
   |  Create tmp dir|
   +--------+-------+
            |
            v
   +----------------------------+
   |  Build Variants            |
   |  - FB2 (*.info + fb2-*.inp)|
   |  - USR (*.info + usr-*.inp)|
   +--------+-------------------+
            |
            v
   +----------------------------+
   |  Count Books in each       |
   |  variant (.inp files)      |
   +--------+-------------------+
            |
            v
   +----------------------------+
   |  Update INPX Headers       |
   |  - Total book count        |
   |  - Archive version info    |
   +--------+-------------------+
            |
            v
   +----------------+
   |  Clean tmp dir |
   +--------+-------+
            |
            v
   +----------------+
   |  Output files  |
   |  (output/)     |
   +----------------+
markdown
Copy code

**Explanation:**  

- **Input INPX:** Original archive in `data/` folder.  
- **Select file:** Choose the INPX file interactively using `fzf`.  
- **Temporary folder:** Used for intermediate extraction and counting.  
- **Build Variants:** Generate FB2 and USR INPX files using filtering rules.  
- **Count Books:** Iterate over extracted `.inp` files to determine book count.  
- **Update Headers:** Insert metadata including total books and archive date.  
- **Clean tmp dir:** Remove all temporary files to keep project clean.  
- **Output files:** Final INPX archives are stored in `output/` folder.  

---
