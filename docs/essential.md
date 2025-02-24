remove user 
psql -U postgres -d auroville -c "DELETE FROM \"public\".\"User\" WHERE email = 'polletkiro@gmail.com';"
