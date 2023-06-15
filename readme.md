## Compile elm into Javascript.
```
elm make .\src\Main.elm --optimize --output=./server/static/main.js
```

## Start the server
```
cd server
python -m http.server
```
