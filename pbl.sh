#!/bin/bash

# ==========================================================
# PROJECT: CENTRALIZED USER MANAGEMENT SYSTEM
# PLATFORM: UBUNTU LINUX
# LANGUAGE: BASH SHELL SCRIPTING
# ==========================================================

# Check root privileges
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Please run this script using sudo."
    exit 1
fi

# Display a message and pause
pause() {
    echo
    read -rp "Press Enter to continue..."
}

# Check whether a user exists
user_exists() {
    getent passwd "$1" >/dev/null 2>&1
}

# Check whether a group exists
group_exists() {
    getent group "$1" >/dev/null 2>&1
}

# Display the main menu
show_menu() {
    clear
    echo "================================================"
    echo "       CENTRALIZED USER MANAGEMENT SYSTEM"
    echo "================================================"
    echo " 1. Create a new user"
    echo " 2. Modify an existing user"
    echo " 3. Delete a user"
    echo " 4. Change user password"
    echo " 5. Create a new group"
    echo " 6. Modify a group name"
    echo " 7. Delete a group"
    echo " 8. Show all users"
    echo " 9. Show all groups"
    echo "10. Show groups of a user"
    echo "11. Show users in a group"
    echo "12. Add a user to a group"
    echo "13. Exit"
    echo "================================================"
}

# 1. Create a new user
create_user() {
    read -rp "Enter new username: " username

    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*\$?$ ]]; then
        echo "Invalid username format."
        return
    fi

    if user_exists "$username"; then
        echo "User '$username' already exists."
        return
    fi

    if useradd -m -s /bin/bash "$username"; then
        echo "User created successfully."

        echo "Set the password for $username:"
        if ! passwd "$username"; then
            echo "WARNING: Password was not set successfully."
        fi
    else
        echo "Failed to create user."
    fi
}

# 2. Modify an existing user
modify_user() {
    read -rp "Enter username to modify: " username

    if ! user_exists "$username"; then
        echo "User does not exist."
        return
    fi

    echo "1. Change username"
    echo "2. Change full name/comment"
    echo "3. Change login shell"
    read -rp "Choose modification: " choice

    case "$choice" in
        1)
            read -rp "Enter new username: " newname

            if [[ ! "$newname" =~ ^[a-z_][a-z0-9_-]*\$?$ ]]; then
                echo "Invalid username format."
                return
            fi

            if user_exists "$newname"; then
                echo "New username already exists."
                return
            fi

            if usermod -l "$newname" "$username"; then
                echo "Username changed successfully."
                echo "The existing home directory was not renamed."
            else
                echo "Failed to change username."
            fi
            ;;
        2)
            read -rp "Enter full name: " fullname

            if usermod -c "$fullname" "$username"; then
                echo "User information updated."
            else
                echo "Failed to update user information."
            fi
            ;;
        3)
            read -rp "Enter shell path (e.g. /bin/bash): " shellpath

            if [[ ! -x "$shellpath" || ! -f "$shellpath" ]]; then
                echo "Invalid or non-executable shell path."
                return
            fi

            if usermod -s "$shellpath" "$username"; then
                echo "Login shell updated."
            else
                echo "Failed to update login shell."
            fi
            ;;
        *)
            echo "Invalid modification option."
            ;;
    esac
}

# 3. Delete a user
delete_user() {
    read -rp "Enter username to delete: " username

    if ! user_exists "$username"; then
        echo "User does not exist."
        return
    fi

    echo "WARNING: This deletes the account."
    echo "The user's home directory will be retained."
    read -rp "Type DELETE to confirm: " confirm

    if [[ "$confirm" == "DELETE" ]]; then
        if userdel "$username"; then
            echo "User deleted successfully."
        else
            echo "Failed to delete user."
        fi
    else
        echo "Deletion cancelled."
    fi
}

# 4. Change user password
change_password() {
    read -rp "Enter username: " username

    if ! user_exists "$username"; then
        echo "User does not exist."
        return
    fi

    passwd "$username"
}

# 5. Create a group
create_group() {
    read -rp "Enter new group name: " groupname

    if [[ ! "$groupname" =~ ^[a-z_][a-z0-9_-]*\$?$ ]]; then
        echo "Invalid group name format."
        return
    fi

    if group_exists "$groupname"; then
        echo "Group already exists."
        return
    fi

    if groupadd "$groupname"; then
        echo "Group created successfully."
    else
        echo "Failed to create group."
    fi
}

# 6. Modify a group name
modify_group() {
    read -rp "Enter existing group name: " oldgroup

    if ! group_exists "$oldgroup"; then
        echo "Group does not exist."
        return
    fi

    read -rp "Enter new group name: " newgroup

    if [[ ! "$newgroup" =~ ^[a-z_][a-z0-9_-]*\$?$ ]]; then
        echo "Invalid group name format."
        return
    fi

    if group_exists "$newgroup"; then
        echo "New group name already exists."
        return
    fi

    if groupmod -n "$newgroup" "$oldgroup"; then
        echo "Group name modified successfully."
    else
        echo "Failed to modify group."
    fi
}

# 7. Delete a group
delete_group() {
    read -rp "Enter group name to delete: " groupname

    if ! group_exists "$groupname"; then
        echo "Group does not exist."
        return
    fi

    echo "WARNING: Group deletion may affect access permissions."
    read -rp "Type DELETE to confirm: " confirm

    if [[ "$confirm" == "DELETE" ]]; then
        if groupdel "$groupname"; then
            echo "Group deleted successfully."
        else
            echo "Failed to delete group."
            echo "Check whether it is a user's primary group."
        fi
    else
        echo "Deletion cancelled."
    fi
}

# 8. Display all users
show_users() {
    echo "========== ALL SYSTEM USERS =========="
    getent passwd | cut -d: -f1
}

# 9. Display all groups
show_groups() {
    echo "========== ALL SYSTEM GROUPS =========="
    getent group | cut -d: -f1
}

# 10. Display groups of a user
show_user_groups() {
    read -rp "Enter username: " username

    if ! user_exists "$username"; then
        echo "User does not exist."
        return
    fi

    echo "Groups of user '$username':"
    id -nG "$username"
}

# 11. Display users belonging to a group
show_group_users() {
    read -rp "Enter group name: " groupname

    if ! group_exists "$groupname"; then
        echo "Group does not exist."
        return
    fi

    echo "Users belonging to group '$groupname':"

    found=0

    while IFS=: read -r username _ _ _ _ _ _; do
        if id -nG "$username" 2>/dev/null |
            tr ' ' '\n' |
            grep -Fxq -- "$groupname"; then
            echo "$username"
            found=1
        fi
    done < <(getent passwd)

    if [[ "$found" -eq 0 ]]; then
        echo "No users found in this group."
    fi
}

# 12. Add a user to a group
add_user_to_group() {
    read -rp "Enter username: " username
    read -rp "Enter group name: " groupname

    if ! user_exists "$username"; then
        echo "User does not exist."
        return
    fi

    if ! group_exists "$groupname"; then
        echo "Group does not exist."
        return
    fi

    if usermod -aG "$groupname" "$username"; then
        echo "User added to group successfully."
        echo "Current supplementary groups:"
        id -nG "$username"
    else
        echo "Failed to add user to group."
    fi
}

# Main program loop
while true; do
    show_menu

    read -rp "Enter your choice (1-13): " choice

    case "$choice" in
        1)  create_user ;;
        2)  modify_user ;;
        3)  delete_user ;;
        4)  change_password ;;
        5)  create_group ;;
        6)  modify_group ;;
        7)  delete_group ;;
        8)  show_users ;;
        9)  show_groups ;;
        10) show_user_groups ;;
        11) show_group_users ;;
        12) add_user_to_group ;;
        13)
            echo "Thank you for using the system."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select 1-13."
            ;;
    esac

    pause
done
