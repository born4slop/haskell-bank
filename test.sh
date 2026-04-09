
BASE_URL="http://localhost:8080/api/v1"

echo "=== 1. УСПЕШНЫЙ СЦЕНАРИЙ: Получить инфу о себе ==="
curl -s -X GET "$BASE_URL/accounts/me" | jq

echo -e "\n=== 2. УСПЕШНЫЙ СЦЕНАРИЙ: Перевод денег ==="
RESPONSE=$(curl -s -X POST "$BASE_URL/transfers" \
  -H "Content-Type: application/json" \
  -d '{"to_acc": "ACC123", "amount": 500.0}')
echo $RESPONSE | jq

TX_ID=$(echo $RESPONSE | grep -o '"id":"[^"]*' | grep -o '[^"]*$')

echo -e "\n=== 3. УСПЕШНЫЙ СЦЕНАРИЙ: Проверить статус перевода ==="
curl -s -X GET "$BASE_URL/transfers/$TX_ID" | jq

echo -e "\n=== 4. УСПЕШНЫЙ СЦЕНАРИЙ: Посмотреть историю ==="
curl -s -X GET "$BASE_URL/accounts/me/history" | jq

echo -e "\n=== 5. НЕУСПЕШНЫЙ СЦЕНАРИЙ (POST /transfers): Недостаточно средств ==="
curl -s -w "\n[HTTP Status: %{http_code}]\n" -X POST "$BASE_URL/transfers" \
  -H "Content-Type: application/json" \
  -d '{"to_acc": "ACC123", "amount": 99999.0}'

echo -e "\n=== 6. НЕУСПЕШНЫЙ СЦЕНАРИЙ (GET /transfers/{id}): Транзакция не найдена ==="
curl -s -w "\n[HTTP Status: %{http_code}]\n" -X GET "$BASE_URL/transfers/fake-uuid-1234"

echo -e "\n\n=== 7. НЕУСПЕШНЫЙ СЦЕНАРИЙ: Счет получателя не существует ==="
curl -s -w "\n[HTTP Status: %{http_code}]" -X POST "$BASE_URL/transfers" \
  -H "Content-Type: application/json" \
  -d '{"to_acc": "UNKNOWN", "amount": 100.0}'
echo ""