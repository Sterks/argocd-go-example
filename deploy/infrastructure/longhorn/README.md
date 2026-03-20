# Longhorn Access

## Доступ к Longhorn UI

### Вариант 1: Через отдельный порт (рекомендуется)
**Полноценный доступ с узлами и дисками**

- **HTTP**: http://192.168.0.200:8081/
- **HTTPS**: https://192.168.0.200:8082/

Этот вариант предоставляет полный доступ к Longhorn UI со всеми функциями:
- ✅ Просмотр узлов (Nodes)
- ✅ Просмотр дисков (Disks)
- ✅ Управление томами (Volumes)
- ✅ Настройки (Settings)

### Вариант 2: Через DNS имя
**Требуется настройка DNS или /etc/hosts**

Добавьте в `/etc/hosts` на вашем компьютере:
```
192.168.0.200 longhorn.local
```

Затем откройте:
- **HTTP**: http://longhorn.local/
- **HTTPS**: https://longhorn.local/

### Вариант 3: Через subpath (ограниченный)
**Только UI, API не работает**

- **URL**: https://192.168.0.200/longhorn/

⚠️ **Ограничения:**
- UI загружается, но не отображает узлы и диски
- API вызовы не работают из-за редиректов Longhorn
- Подходит только для базового просмотра

## Почему subpath не работает?

Longhorn UI использует жестко закодированные редиректы на корень `/` вместо относительных путей. При доступе через `/longhorn/`:
1. UI загружается успешно
2. API запросы перенаправляются на `/v1/nodes` вместо `/longhorn/v1/nodes`
3. Браузер не может загрузить данные API

## Проверка через kubectl

```bash
# Просмотр всех узлов
kubectl get node.longhorn.io -n longhorn-system

# Просмотр дисков на node1
kubectl get node.longhorn.io/node1 -n longhorn-system -o yaml | grep -A 10 "disks:"

# Проверка настроек Longhorn
kubectl get setting -n longhorn-system | head -20
```
