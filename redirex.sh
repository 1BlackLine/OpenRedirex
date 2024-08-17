#!/bin/bash

export LHOST="https://evil.com"
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Pilih mode pemindaian:"
echo "1) Single target"
echo "2) Mass scan dari daftar subdomain"
read -p "Masukkan pilihan Anda (1/2): " mode

echo "Pilih jenis payload:"
echo "1) Basic payload (https://evil.com)"
echo "2) Custom payload dari file"
read -p "Masukkan pilihan Anda (1/2): " payload_mode

if [ "$payload_mode" == "1" ]; then
  payload_list=("$LHOST")
elif [ "$payload_mode" == "2" ]; then
  read -p "Masukkan path ke file daftar payload: " payload_file
  
  if [ ! -f "$payload_file" ]; then
    echo "File tidak ditemukan: $payload_file"
    exit 1
  fi
  
  mapfile -t payload_list < "$payload_file"
else
  echo "Pilihan tidak valid. Keluar."
  exit 1
fi

# Tanya apakah hasil akan disimpan
read -p "Apakah Anda ingin menyimpan hasil yang rentan? (y/n): " save_results
if [ "$save_results" == "y" ]; then
  read -p "Masukkan nama file untuk menyimpan hasil: " output_file
  echo "Menyimpan hasil ke $output_file..."
  > "$output_file"  # Buat file kosong atau timpa jika sudah ada
fi

scan_domain() {
  domain=$1
  echo "Memindai $domain untuk kerentanan open redirect..."

  for payload in "${payload_list[@]}"; do
    gau $domain | gf redirect | qsreplace "$payload" | while read url; do
      if curl -Is "$url" 2>&1 | grep -q "Location: $payload"; then
        echo -e "${RED}VULN! $url${NC}"
        if [ "$save_results" == "y" ]; then
          echo "VULN! $url" >> "$output_file"
        fi
      else
        echo "Not vulnerable: $url"
      fi
    done
  done
}

if [ "$mode" == "1" ]; then
  read -p "Masukkan URL target: " domain
  scan_domain "$domain"

elif [ "$mode" == "2" ]; then
  read -p "Masukkan path ke file daftar subdomain: " subdomain_file
  
  if [ ! -f "$subdomain_file" ]; then
    echo "File tidak ditemukan: $subdomain_file"
    exit 1
  fi
  
  cat "$subdomain_file" | while read domain; do
    scan_domain "$domain"
  done
  
else
  echo "Pilihan tidak valid. Keluar."
  exit 1
fi

if [ "$save_results" == "y" ]; then
  echo "Hasil yang rentan telah disimpan di $output_file."
fi
