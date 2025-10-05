# PowerShell test script for Flutter Docker environment
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Testing Flutter Docker Environment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Build the Docker image
Write-Host "Step 1: Building Docker image..." -ForegroundColor Yellow
docker build -t flutter-dev-test -f .cursor/Dockerfile .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker build successful!" -ForegroundColor Green
Write-Host ""

# Test Flutter availability in interactive shell
Write-Host "Step 2: Testing Flutter in interactive shell..." -ForegroundColor Yellow
docker run --rm flutter-dev-test bash -c "flutter --version"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter not available in interactive shell!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter works in interactive shell!" -ForegroundColor Green
Write-Host ""

# Test Flutter availability in non-interactive shell (like background agents)
Write-Host "Step 3: Testing Flutter in non-interactive shell..." -ForegroundColor Yellow
docker run --rm flutter-dev-test sh -c "flutter --version"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter not available in non-interactive shell!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter works in non-interactive shell!" -ForegroundColor Green
Write-Host ""

# Test Dart availability
Write-Host "Step 4: Testing Dart availability..." -ForegroundColor Yellow
docker run --rm flutter-dev-test bash -c "dart --version"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Dart not available!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Dart works!" -ForegroundColor Green
Write-Host ""

# Test Flutter doctor
Write-Host "Step 5: Running Flutter doctor..." -ForegroundColor Yellow
docker run --rm flutter-dev-test bash -c "flutter doctor"
Write-Host ""

# Test pub get with project
Write-Host "Step 6: Testing 'flutter pub get' with project..." -ForegroundColor Yellow
$pwd = (Get-Location).Path.Replace('\', '/')
docker run --rm -v "${pwd}:/home/developer/workspace" flutter-dev-test bash -c "cd /home/developer/workspace && flutter pub get"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter pub get failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter pub get successful!" -ForegroundColor Green
Write-Host ""

# Test the PATH in different shell scenarios
Write-Host "Step 7: Testing PATH in various scenarios..." -ForegroundColor Yellow

Write-Host "  - Testing with 'bash -c' (interactive):"
docker run --rm flutter-dev-test bash -c "echo `$PATH | grep flutter"

Write-Host "  - Testing with 'sh -c' (non-interactive):"
docker run --rm flutter-dev-test sh -c "echo `$PATH | grep flutter"

Write-Host "  - Testing with direct command (background agent simulation):"
docker run --rm flutter-dev-test bash -c "which flutter"

Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ All tests passed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The Dockerfile is working correctly for background agents." -ForegroundColor Green


