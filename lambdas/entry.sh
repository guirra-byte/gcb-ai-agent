#!/bin/bash

# Entry point script para Lambda
# Suporta execução local (com RIE) e na AWS

set -e

if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
    # Rodando localmente - usa o Lambda RIE (Runtime Interface Emulator)
    echo "🔧 Modo LOCAL detectado - usando Lambda Runtime Interface Emulator"
    exec /usr/local/bin/aws-lambda-rie python -m awslambdaric "$@"
else
    # Rodando na AWS - usa o Lambda Runtime Interface Client normal
    echo "☁️  Modo AWS detectado - usando Lambda Runtime Interface Client"
    exec python -m awslambdaric "$@"
fi

