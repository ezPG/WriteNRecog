from fastapi import FastAPI, File
from infrence import get_number

app = FastAPI()

@app.get("/")
async def root():
    return {"status":"Ok","message": "API is running"}

@app.post("/upload_img/")
async def create_file(file: bytes = File(description="A file read as bytes")):
    with open(f'img.jpg','wb') as image:
        image.write(file)
        image.close()
    print("[INFO] Image uploaded successfully")
    rec_number = get_number()
    print("rec_number:",rec_number)
    return {"status": "Ok", "message": "Image uploaded successfully","value": rec_number}