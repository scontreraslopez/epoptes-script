  #!/bin/bash

# Solicitar usuario y contraseña
read -p "Usuario: " user
read -sp "Contraseña: " password
echo

# Leer el contenido de targets.txt
while IFS= read -r target; do
    echo "Conectando a $target..."
    
    # Conectar por SSH y realizar las comprobaciones
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$user@$target" << EOF
        file="/etc/default/epoptes-client"
        option="VNCVIEWER_OPTIONS=\"-menukey none\""
        changed=false
        
        if grep -q "^VNCVIEWER_OPTIONS=" "\$file"; then
            current_option=\$(grep "^VNCVIEWER_OPTIONS=" "\$file")
            if [ "\$current_option" != "\$option" ]; then
                echo "$password" | sudo -S sed -i "s|^VNCVIEWER_OPTIONS=.*|\$option|" "\$file"
                echo "Opción actualizada en \$file"
                changed=true
            else
                echo "La opción ya está configurada correctamente en \$file"
            fi
        else
            echo "\$option" | echo "$password" | sudo -S tee -a "\$file"
            echo "Opción añadida a \$file"
            changed=true
        fi
        
        if [ "\$changed" = true ]; then
            echo "$password" | sudo -S systemctl restart epoptes-client
            echo "Servicio epoptes-client reiniciado"
        fi
EOF

    echo "Desconectado de $target"
done < targets.txt
