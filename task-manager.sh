#!/bin/bash
exec &>/dev/null
#===================================
# Проверяем среднюю загрузку ядер
get_load() {
  total_load=0
  count=0
  vmstat 1 5 | tail -n 5 | awk '{total += $13; count++}'
  avg_load=$(bc <<< "scale=2; $total_load / $count")
  echo "$avg_load"
}

# Балансировка процессов по нагрузке
balance_processes() {
  cores=$(grep -c ^processor /proc/cpuinfo)
  ps -eo pid=%p,cmd=%c,%cpu=%C --sort=-%CPU | head -n 10 | while read -r line; do
    pid=$(echo "$line" | awk '{print $1}')
    cpu_usage=$(echo "$line" | awk '{print $3}')
    # Привязываем процесс к наименее загруженному ядру
    least_loaded_core=$(find_least_loaded_core)
    taskset -pc "$least_loaded_core" "$pid" 2>/dev/null || echo "Ошибка привязки задачи $pid к ядру $least_loaded_core"
  done
}

# Поиск наименее загруженного ядра
find_least_loaded_core() {
  max_load=100.0
  least_loaded_core=0
  for core in $(seq 0 $((cores-1))); do
    usage=$(get_core_load "$core")
    if (( $(printf "%.0f\n" "$usage") < $(printf "%.0f\n" "$max_load") )); then
      max_load=$usage
      least_loaded_core=$core
    fi
  done
  echo "$least_loaded_core"
}

# Определение текущей нагрузки отдельного ядра
get_core_load() {
  local core=$1
  mpstat -P ALL 1 1 | grep "^$core" | awk '{print $3+$4}'
}

# Главный цикл мониторинга
while true; do
  current_load=$(get_load)
  if (( $(printf '%.0f\n' "$current_load") > 70 )); then
    balance_processes
  fi
  sleep 5
done
