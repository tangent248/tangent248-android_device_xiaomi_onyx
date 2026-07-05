#!/vendor/bin/sh

CONFIG_DIR="/data/vendor/irqbalance"
DYN_CONF="$CONFIG_DIR/msm_irqbalance.conf"

# Base ignored IRQs that are statically defined or rarely change
IGNORED_IRQS="11,13,17"

# Function to dynamically find IRQ, set affinity, and add to the ignore list
tune_irq() {
    local irq_name="$1"
    local cpu_mask="$2"
    
    # Parse /proc/interrupts for the exact IRQ number matching the name
    local irq_num=$(grep -w "$irq_name" /proc/interrupts | awk -F: '{print $1}' | tr -d ' ')
    
    if [ -n "$irq_num" ]; then
        # Append to the ignored list so msm_irqbalance leaves it alone
        IGNORED_IRQS="${IGNORED_IRQS},${irq_num}"
        
        # Apply SMP affinity
        if [ -w "/proc/irq/$irq_num/smp_affinity_list" ]; then
            echo "$cpu_mask" > "/proc/irq/$irq_num/smp_affinity_list"
            log -t "Onyx-IRQ" "Tuned $irq_name (IRQ $irq_num) to CPU $cpu_mask"
        fi
    else
        log -t "Onyx-IRQ" "Warning: Could not find IRQ for $irq_name"
    fi
}

# Apply SM8735 All-Big-Core specific affinities
tune_irq "ufshcd" "0-1"
tune_irq "xiaomi_tp" "2"
tune_irq "gmu" "3"
tune_irq "hfi" "3"
tune_irq "msm_drm" "4"

# Write out the dynamic msm_irqbalance configuration
echo "# Dynamic SM8735 IRQ Balance Config" > "$DYN_CONF"
echo "PRIO=1,1,1,1,1,1,1,0" >> "$DYN_CONF"
echo "IGNORED_IRQ=$IGNORED_IRQS" >> "$DYN_CONF"
chmod 0644 "$DYN_CONF"