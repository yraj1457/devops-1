from fastapi import FastAPI, Request
import datetime as dt
import uvicorn

app = FastAPI()

@app.get("/")
def simple_time_service(request: Request):

    timestamp = dt.datetime.utcnow()  # get the timestamp
    ip = request.client.host  # get the ip
    return {"timestamp": f"{timestamp}",
            "ip": f"{ip}"}  


if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=5050, reload=True)