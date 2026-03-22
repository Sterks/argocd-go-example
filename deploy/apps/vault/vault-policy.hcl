# Политика для приложения go-app
path "secret/data/go-app/*" {
  capabilities = ["read", "list"]
}

path "secret/metadata/go-app/*" {
  capabilities = ["read", "list"]
}
