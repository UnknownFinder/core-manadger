#!/bin/bash

# Определяем число ядер
#total_cores=$(grep -c ^processor /proc/cpuinfo)

# Функция для оценки текущей загрузки CPU
#get_core_load() {
#  local core_id=$1
#  vmstat -n 1 2 | tail -1 | awk "{print \$${core_id+14}}"
#}

# Балансировка процессов по нагрузке
#balance_processes() {
 # local max_load=0
 # local max_core=-1
 # local min_load=100
 # local min_core=-1

  # Оцениваем нагрузку на каждом ядре
#  for ((i=0; i<$total_cores; i++)); do
#    local load=$(get_core_load $i)
#    if ((load > max_load)); then
#      max_load=$load
#      max_core=$i
#    fi
#    if ((load < min_load)); then
#      min_load=$load
#      min_core=$i
#    fi
#  done

#  # Если разница большая, перемещаем процессы
#  if ((max_load - min_load > 20)); then
#    ps -eo pid,cmd,%cpu --sort=-%cpu | head -n 10 | while read line; do
#      pid=$(echo $line | awk '{print $1}')
#      taskset -pc $min_core $pid
#    done
#  fi
#}

#while true; do
#  balance_processes
#  sleep 5
#done
exec &>/dev/null
#===================================
# Проверяем загрузку ядер
get_load() {
  vmstat 1 2 | tail -1 | awk '{print $13}'  # Среднюю загрузку
}

# Балансировка процессов по нагрузке
balance_processes() {
  cores=$(grep -c ^processor /proc/cpuinfo)
  ps -eo pid,cmd,%cpu --sort=-%cpu | head -n 10 | while read line; do
    pid=$(echo $line | awk '{print $1}')
    cpu_usage=$(echo $line | awk '{print $3}')
    
    # Привязываем процесс к наименее загруженному ядру
    least_loaded_core=$(find_least_loaded_core)
    taskset -pc $least_loaded_core $pid
  done
}

# Функция поиска наименьшей загрузки ядра
find_least_loaded_core() {
  max_load=100
  least_loaded_core=0
  for core in $(seq 0 $((cores-1))); do
    usage=$(get_core_load $core)
    if ((usage < max_load)); then
      max_load=$usage
      least_loaded_core=$core
    fi
  done
  echo $least_loaded_core
}

# Определяем нагрузку отдельного ядра
get_core_load() {
  local core=$1
  mpstat -P ALL 1 1 | grep "^$core" | awk '{print $3+$4}'
}

# Основной цикл мониторинга
while true; do
  current_load=$(get_load)
  if (($current_load > 70)); then
    balance_processes
  fi
  sleep 5
done

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
  ps -eo pid=%p,cmd=%c,%cpu=%C --sort=-%CPU | head -n 10 | while read line; do
    pid=$(echo $line | awk '{print $1}')
    cpu_usage=$(echo $line | awk '{print $3}')
    
    # Привязываем процесс к наименее загруженному ядру
    least_loaded_core=$(find_least_loaded_core)
    taskset -pc $least_loaded_core $pid 2>/dev/null || echo "Ошибка привязки задачи $pid к ядру $least_loaded_core"
  done
}

# Поиск наименее загруженного ядра
find_least_loaded_core() {
  max_load=100.0
  least_loaded_core=0
  for core in $(seq 0 $((cores-1))); do
    usage=$(get_core_load $core)
    if (( $(printf "%.0f\n" "$usage") < $(printf "%.0f\n" "$max_load") )); then
      max_load=$usage
      least_loaded_core=$core
    fi
  done
  echo $least_loaded_core
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




















































