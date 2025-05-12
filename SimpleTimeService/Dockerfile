# Python image
FROM python:3.11-slim

# Non-root user
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Working directory inside the container
WORKDIR /app

# Copy requirements list first
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the actual application code
COPY app.py .

# Set ownership of the app files to the non-root user
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose the port the app will run on
EXPOSE 5050

# Start the FastAPI server using uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5050"]
