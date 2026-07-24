#!/vendor/bin/sh

# dynamically find IRQ and set affinity
tune_irq() {
    local irq_name="$1"
    local cpu_mask="$2"

    # Parse /proc/interrupts for the exact IRQ number matching the name
    local irq_num=$(grep -w "$irq_name" /proc/interrupts | awk -F: '{print $1}' | tr -d ' ')

    if [ -n "$irq_num" ]; then
        # Apply affinity
        if [ -w "/proc/irq/$irq_num/smp_affinity_list" ]; then
            echo "$cpu_mask" > "/proc/irq/$irq_num/smp_affinity_list"
            log -t "Onyx-IRQ" "Tuned $irq_name (IRQ $irq_num) to CPU $cpu_mask"
        fi
    else
        log -t "Onyx-IRQ" "Warning: Could not find IRQ for $irq_name"
    fi
}

# Apply affinities
tune_irq "ufshcd" "1"
tune_irq "gmu" "5"
tune_irq "hfi" "5"
tune_irq "msm_drm" "6"
tune_irq "xiaomi_tp" "6"