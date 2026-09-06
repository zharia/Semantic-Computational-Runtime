#!/usr/bin/env bash
# kanban.sh - A pure filesystem-based Kanban board manager

BOARD_DIR="kanban"
COLUMNS=("1-backlog" "2-todo" "3-in-progress" "4-done")

# Initialize the filesystem structure
init_board() {
    mkdir -p "$BOARD_DIR"
    for col in "${COLUMNS[@]}"; do
        mkdir -p "$BOARD_DIR/$col"
    done
}

# Create a new task file
add_task() {
    local task_name="$1"
    local desc="$2"
    if [ -z "$task_name" ]; then
        echo "Error: Task name required."
        return 1
    fi
    init_board
    # Clean file name
    local filename=$(echo "$task_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local filepath="$BOARD_DIR/1-backlog/$filename.txt"

    echo "Title: $task_name" > "$filepath"
    echo "Created: $(date '+%Y-%m-%d %H:%M:%S')" >> "$filepath"
    echo "----------------------------------------" >> "$filepath"
    echo -e "Description:\n$desc" >> "$filepath"
    echo "Task created in Backlog: $filepath"
}

# Move a task file between folders
move_task() {
    local task_file="$1"
    local dest_col_index="$2"

    init_board
    # Find where the file currently lives
    local source_path=$(find "$BOARD_DIR" -name "$task_file" -print -quit)

    if [ -z "$source_path" ] || [ ! -f "$source_path" ]; then
        echo "Error: Task file '$task_file' not found anywhere in the board."
        return 1
    fi

    # Map index to column folder
    if [ "$dest_col_index" -lt 1 ] || [ "$dest_col_index" -gt 4 ]; then
        echo "Error: Target column must be 1 (Backlog), 2 (To Do), 3 (In Progress), or 4 (Done)."
        return 1
    fi

    local target_col="${COLUMNS[$((dest_col_index-1))]}"
    mv "$source_path" "$BOARD_DIR/$target_col/"
    echo "Moved '$(basename "$source_path")' to $target_col"
}

# Render a side-by-side terminal board view
show_board() {
    init_board
    echo "================================================================================="
    echo "                            FILESYSTEM KANBAN BOARD                              "
    echo "================================================================================="
    printf "%-20s | %-20s | %-20s | %-20s\n" "[1] BACKLOG" "[2] TO DO" "[3] IN PROGRESS" "[4] DONE"
    echo "---------------------+----------------------+----------------------+---------------------"

    # Read files in each column into arrays
    local c1=($(ls "$BOARD_DIR/1-backlog"))
    local c2=($(ls "$BOARD_DIR/2-todo"))
    local c3=($(ls "$BOARD_DIR/3-in-progress"))
    local c4=($(ls "$BOARD_DIR/4-done"))

    # Find max rows to display
    local max=${#c1[@]}
    [ ${#c2[@]} -gt $max ] && max=${#c2[@]}
    [ ${#c3[@]} -gt $max ] && max=${#c3[@]}
    [ ${#c4[@]} -gt $max ] && max=${#c4[@]}

    if [ $max -eq 0 ]; then
        echo "                                 (Board is empty)                                "
    else
        for ((i=0; i<max; i++)); do
            printf "%-20.20s | %-20.20s | %-20.20s | %-20.20s\n" "${c1[i]}" "${c2[i]}" "${c3[i]}" "${c4[i]}"
        done
    fi
    echo "================================================================================="
}

# Command router
case "$1" in
    init) init_board; echo "Kanban board initialized at ./$BOARD_DIR/" ;;
    add)  add_task "$2" "$3" ;;
    move) move_task "$2" "$3" ;;
    view) show_board ;;
    *)    echo "Usage: $0 {init|add \"Task Title\" \"Desc\"|move task-file.txt [1-4]|view}" ;;
esac
