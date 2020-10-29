#!/bin/bash

# install gromit-mpx
sudo apt install -y gromit-mpx

# install obs
sudo apt install -y obs-studio

# download gnome bDMZ cursor theme
if [ ! -f "160115-bDMZT.tar.gz" ]; then
	wget "https://dllb2.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjE0NjA3MzQ5NzMiLCJ1IjpudWxsLCJsdCI6ImRvd25sb2FkIiwicyI6ImVkMzkyMWYwNGFlMTBkNGZjNzA2YWNiZWZlM2M1ODA3NDZiNjVlOWU0ODg1ZWNhZDQxMzZmMDliZmQxZWZkMGYxOGNlNjZmMzFjNzZlNGRmNDM0ZWQ2YWI2M2FkOTYyODhhYmI0MzU1NWRkNTJlYzUxM2Y3NTIwN2ExNmIxNzcwIiwidCI6MTU4NDc0NTMwNiwic3RmcCI6IjgwOGRjODUzMzRjMjVkODBhZDc4NmMzZDZkZWVmOWNhIiwic3RpcCI6IjJhMDE6ZTM1OjJlOWI6Y2Y4MDo2YTgwOjEzNjA6ZGE1MDphMjM0In0.WgHrW5rITQobEunvcScF0Wj6rsd2fdRWWuFXoUVDeOs/160115-bDMZT.tar.gz"
fi

# install gnome bDMZT cursor theme
tar -xzf ./160115-bDMZT.tar.gz -C ./
if [ ! -d "/usr/share/icons/bbDMZ" ]; then
	sudo mv bDMZT/bbDMZ /usr/share/icons/
fi
rm -r bDMZT/

