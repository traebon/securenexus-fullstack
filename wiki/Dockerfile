FROM squidfunk/mkdocs-material:latest

# Install additional plugins
RUN pip install --no-cache-dir \
    mkdocs-glightbox \
    mkdocs-macros-plugin

# Set working directory
WORKDIR /docs

# Copy all documentation
COPY . /docs

# Expose port
EXPOSE 8000

# Run MkDocs development server
CMD ["serve", "--dev-addr=0.0.0.0:8000"]
