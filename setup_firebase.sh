#!/bin/bash

# Script de configuração do Firebase para Master Checkers
# Execute: bash setup_firebase.sh

set -e

echo "============================================"
echo "  Master Checkers - Firebase Setup Script"
echo "============================================"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar Flutter
echo "📱 Verificando Flutter..."
if command_exists flutter; then
    flutter --version | head -n 1
    echo -e "${GREEN}✓ Flutter encontrado${NC}"
else
    echo -e "${RED}✗ Flutter não encontrado${NC}"
    echo "Por favor, instale o Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi
echo ""

# Verificar Dart
echo "🎯 Verificando Dart..."
if command_exists dart; then
    dart --version | head -n 1
    echo -e "${GREEN}✓ Dart encontrado${NC}"
else
    echo -e "${RED}✗ Dart não encontrado${NC}"
    exit 1
fi
echo ""

# Verificar Node.js (necessário para Firebase CLI)
echo "🟢 Verificando Node.js..."
if command_exists node; then
    node --version
    echo -e "${GREEN}✓ Node.js encontrado${NC}"
else
    echo -e "${YELLOW}⚠ Node.js não encontrado${NC}"
    echo "Node.js é necessário para o Firebase CLI"
    echo "Instale em: https://nodejs.org/"
    echo ""
fi
echo ""

# Verificar/Instalar Firebase CLI
echo "🔥 Verificando Firebase CLI..."
if command_exists firebase; then
    firebase --version
    echo -e "${GREEN}✓ Firebase CLI encontrado${NC}"
else
    echo -e "${YELLOW}⚠ Firebase CLI não encontrado${NC}"
    echo ""
    read -p "Deseja instalar o Firebase CLI? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command_exists npm; then
            echo "Instalando Firebase CLI..."
            npm install -g firebase-tools
            echo -e "${GREEN}✓ Firebase CLI instalado${NC}"
        else
            echo -e "${RED}✗ npm não encontrado. Instale Node.js primeiro${NC}"
            exit 1
        fi
    else
        echo "Você pode instalar depois com: npm install -g firebase-tools"
    fi
fi
echo ""

# Verificar/Instalar FlutterFire CLI
echo "🔥 Verificando FlutterFire CLI..."
if command_exists flutterfire; then
    flutterfire --version
    echo -e "${GREEN}✓ FlutterFire CLI encontrado${NC}"
else
    echo -e "${YELLOW}⚠ FlutterFire CLI não encontrado${NC}"
    echo ""
    read -p "Deseja instalar o FlutterFire CLI? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Instalando FlutterFire CLI..."
        dart pub global activate flutterfire_cli

        # Verificar se está no PATH
        if ! command_exists flutterfire; then
            echo ""
            echo -e "${YELLOW}⚠ FlutterFire CLI instalado, mas não está no PATH${NC}"
            echo "Adicione ao seu PATH:"
            echo "  export PATH=\"\$PATH\":\"\$HOME/.pub-cache/bin\""
            echo ""
            echo "Adicione essa linha ao seu ~/.bashrc ou ~/.zshrc e execute:"
            echo "  source ~/.bashrc  # ou source ~/.zshrc"
        else
            echo -e "${GREEN}✓ FlutterFire CLI instalado${NC}"
        fi
    else
        echo "Você pode instalar depois com: dart pub global activate flutterfire_cli"
    fi
fi
echo ""

# Verificar dependências do Flutter
echo "📦 Verificando dependências do Flutter..."
if [ -f "pubspec.yaml" ]; then
    echo "Executando flutter pub get..."
    flutter pub get
    echo -e "${GREEN}✓ Dependências instaladas${NC}"
else
    echo -e "${RED}✗ pubspec.yaml não encontrado${NC}"
    echo "Execute este script na raiz do projeto Flutter"
    exit 1
fi
echo ""

# Verificar arquivo firebase_options.dart
echo "🔍 Verificando configuração do Firebase..."
if [ -f "lib/firebase_options.dart" ]; then
    if grep -q "d8f8e8c8a8b8c8d8e8f8g8" lib/firebase_options.dart; then
        echo -e "${YELLOW}⚠ Configurações do Firebase são placeholders${NC}"
        echo "Você precisa configurar o Firebase corretamente"
        echo ""
        NEEDS_CONFIG=true
    else
        echo -e "${GREEN}✓ Arquivo firebase_options.dart existe e parece configurado${NC}"
        NEEDS_CONFIG=false
    fi
else
    echo -e "${YELLOW}⚠ Arquivo firebase_options.dart não encontrado${NC}"
    NEEDS_CONFIG=true
fi
echo ""

# Perguntar se deseja configurar agora
if [ "$NEEDS_CONFIG" = true ]; then
    echo "============================================"
    echo "  Configuração do Firebase necessária"
    echo "============================================"
    echo ""
    echo "Passos necessários:"
    echo "1. Criar projeto no Firebase Console"
    echo "2. Ativar Authentication (Email/Password e Google)"
    echo "3. Criar Realtime Database"
    echo "4. Executar: firebase login"
    echo "5. Executar: flutterfire configure"
    echo ""
    echo "Consulte o arquivo FIREBASE_SETUP.md para instruções detalhadas"
    echo ""

    if command_exists firebase && command_exists flutterfire; then
        read -p "Deseja executar a configuração agora? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo "Executando firebase login..."
            firebase login

            echo ""
            echo "Executando flutterfire configure..."
            flutterfire configure

            echo ""
            echo -e "${GREEN}✓ Configuração concluída!${NC}"
        else
            echo "Execute manualmente quando estiver pronto:"
            echo "  1. firebase login"
            echo "  2. flutterfire configure"
        fi
    else
        echo -e "${YELLOW}Instale Firebase CLI e FlutterFire CLI primeiro${NC}"
    fi
fi

echo ""
echo "============================================"
echo "  Resumo da Configuração"
echo "============================================"
echo ""

# Verificar status de cada componente
if command_exists flutter; then
    echo -e "${GREEN}✓${NC} Flutter"
else
    echo -e "${RED}✗${NC} Flutter"
fi

if command_exists firebase; then
    echo -e "${GREEN}✓${NC} Firebase CLI"
else
    echo -e "${RED}✗${NC} Firebase CLI"
fi

if command_exists flutterfire; then
    echo -e "${GREEN}✓${NC} FlutterFire CLI"
else
    echo -e "${RED}✗${NC} FlutterFire CLI"
fi

if [ -f "lib/firebase_options.dart" ] && ! grep -q "d8f8e8c8a8b8c8d8e8f8g8" lib/firebase_options.dart; then
    echo -e "${GREEN}✓${NC} Configuração do Firebase"
else
    echo -e "${YELLOW}⚠${NC} Configuração do Firebase (pendente)"
fi

echo ""
echo "============================================"
echo ""
echo "📚 Para mais informações, consulte:"
echo "   - FIREBASE_SETUP.md (guia completo)"
echo "   - https://firebase.flutter.dev/"
echo ""
echo "🎮 Após configurar, execute:"
echo "   flutter run"
echo ""
