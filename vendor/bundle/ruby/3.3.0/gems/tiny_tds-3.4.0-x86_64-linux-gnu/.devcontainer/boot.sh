# Setup test databases and users.
sqlcmd -C -S sqlserver -U sa -P 'c0MplicatedP@ssword' -i ./test/sql/db-create.sql
sqlcmd -C -S sqlserver -U sa -P 'c0MplicatedP@ssword' -i ./test/sql/db-login.sql

# Mark directory as safe in Git so that commands run without warnings.
git config --global --add safe.directory /workspaces/tiny_tds
