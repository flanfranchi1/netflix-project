# Netflix Data Engineering Project: Cloud Automation & IaC

## 1. Project Overview & Inspiration
This project is an advanced implementation of an end-to-end data pipeline on Azure. It was inspired by the content created by [Ansh Lamba](https://github.com/anshlambagit), who provided the original logic and data sources.

The core objective of this version was to evolve the original solution by focusing on **Infrastructure as Code (IaC)** and automation. While the original project provides the foundational data flow, this repository automates the provisioning of all cloud resources, IAM permissions, and notebook deployments using Terraform, eliminating manual configuration within the Azure Portal.

## 2. Architecture
The pipeline follows a modern data engineering workflow:
1.  **Ingestion (ADF):** Automated collection of CSV files from a GitHub HTTP source.
2.  **Storage (Data Lake Gen2):** Data is organized into functional layers: Raw, Bronze, Silver, and Gold.
3.  **Processing (Databricks):** Ingestion and transformation using Spark Structured Streaming and Delta Lake for ACID compliance.
4.  **Orchestration:** Azure Data Factory manages dependencies, copy activities, and Databricks notebook execution.

## 3. Tech Stack
* **IaC:** Terraform (with remote state management in Azure Storage).
* **Cloud Provider:** Microsoft Azure (Data Factory, Storage Account, Databricks).
* **Data Processing:** Python (PySpark), SQL.
* **Security:** Managed Identities and RBAC (Role-Based Access Control) for secure service-to-service communication.

## 4. Key Automation Features
* **Full Infrastructure Automation:** Provisioning of Databricks Workspaces and Single Node clusters entirely via Terraform.
* **Dynamic Pipeline Generation:** Use of Terraform `for_each` loops to dynamically create datasets and pipeline activities for multiple source files.
* **Automated Notebook Deployment:** Notebooks are deployed directly from the repository to the Databricks Workspace via IaC.
* **Remote State Management:** Configured Azure backend to ensure infrastructure consistency and enable CI/CD integration.

## 5. How to Deploy
1. Authenticate via Azure CLI.
2. Initialize the environment using the provided bootstrap script: `bash terraform_state_setup.sh`.
3. Deploy the infrastructure:
   ```bash
   terraform init
   terraform apply