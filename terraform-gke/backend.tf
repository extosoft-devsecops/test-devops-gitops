# ===================================================================
# Backend Configuration - Remote State Storage
# ===================================================================
# แนะนำให้ใช้ GCS Backend แทน local สำหรับ production
#
# ขั้นตอนการตั้งค่า:
# 1. สร้าง GCS bucket สำหรับเก็บ state:
#    gsutil mb -p test-devops-478606 -l asia-southeast1 gs://test-devops-terraform-state
#    gsutil versioning set on gs://test-devops-terraform-state
#
# 2. เปลี่ยนชื่อไฟล์นี้เป็น backend.tf
# 3. Run: terraform init -migrate-state

terraform {
  backend "gcs" {
    # bucket จะถูกกำหนดผ่าน -backend-config ใน Makefile
    # prefix จะถูกกำหนดผ่าน -backend-config ใน Makefile
    # project จะถูกกำหนดผ่าว -backend-config ใน Makefile

    # เปิด state locking เพื่อป้องกันการรัน terraform พร้อมกัน
    # GCS backend ใช้ state locking โดยอัตโนมัติ
  }
}

# สำหรับ Development/Testing อาจใช้ local backend ได้:
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

