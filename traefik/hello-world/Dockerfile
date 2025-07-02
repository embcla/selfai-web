FROM nginx:alpine

# Create a custom index.html that shows the container name
RUN echo '<!DOCTYPE html><html><head><title>Hello World</title></head><body><h1>Hello from container: $HOSTNAME</h1></body></html>' > /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80