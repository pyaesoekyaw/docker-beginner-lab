# Use an official base image (e.g., Alpine, Ubuntu, Python, Node.js, etc.)
FROM alpine:latest
# Set the working directory inside the container
WORKDIR /app
# Copy files from your host machine into the container
COPY . .
# Install dependencies (if needed)
RUN apk add --no-cache python3 py3-pip  # Example for Alpine Linux
# Define the default command to run when the container starts
CMD ["echo", "Hello, Docker!"]  
