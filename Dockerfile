# ============================================================
#  Dockerfile — Wholesale Shop Backend
#  Multi-stage build: keeps the final image small
# ============================================================

# ── Stage 1: Install dependencies ────────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app

# Copy only package files first (leverages Docker layer cache)
COPY backend/package*.json ./
RUN npm install --omit=dev

# ── Stage 2: Final runtime image ─────────────────────────────
FROM node:20-alpine AS runtime
WORKDIR /app

# Create a non-root user for security (least-privilege principle)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy production node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application source
COPY backend/  ./backend/
COPY frontend/ ./frontend/

# Set working directory to backend where server.js lives
WORKDIR /app/backend

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 3000

# Health check — Docker / ECS will use this to determine container health
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Start the server
CMD ["node", "server.js"]
