# Use the Flutter base image
FROM ghcr.io/cirruslabs/flutter:latest AS build

# Set working directory
WORKDIR /app

# Copy pubspec and install dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the entire Flutter project
COPY . .

# Build the Flutter web app
RUN flutter build web --release

# Use an Nginx image to serve the Flutter app
FROM nginx:alpine

# Set working directory
WORKDIR /usr/share/nginx/html

# Remove default Nginx static files
RUN rm -rf ./*

# Copy the built Flutter app from the build stage
COPY --from=build /app/build/web .

COPY default.conf /etc/nginx/conf.d/

# Expose port 3000
EXPOSE 3000

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
