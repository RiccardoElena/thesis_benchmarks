#!/usr/bin/env python3

import subprocess
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import numpy as np
import matplotlib
matplotlib.use('Agg') 

def create_individual_plots(numbers, units_num, max_len_idx, pred_num):
    
    # Grafico per unitsNum
    plt.figure(figsize=(20, 6))
    plt.plot(numbers, units_num, 'bo-', markersize=4, linewidth=1)
    plt.xlabel('Numero del ciclo')
    plt.ylabel('unitsNum')
    plt.title('unitsNum vs Numero del ciclo')
    plt.grid(True, alpha=0.3)
    plt.xticks(numbers, fontsize=6)
    plt.subplots_adjust(bottom=0.15)
    plt.savefig('unitsNum_plot.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Grafico per maxLenIdx
    plt.figure(figsize=(20, 6))
    plt.plot(numbers, max_len_idx, 'ro-', markersize=4, linewidth=1)
    plt.xlabel('Numero del ciclo')
    plt.ylabel('maxLenIdx')
    plt.title('maxLenIdx vs Numero del ciclo')
    plt.xticks(numbers, fontsize=6)  # Mostra tutti i numeri
    plt.subplots_adjust(bottom=0.15)
    plt.grid(True, alpha=0.3)
    plt.savefig('maxLenIdx_plot.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Grafico per predNum
    plt.figure(figsize=(20, 6))
    plt.plot(numbers, pred_num, 'go-', markersize=4, linewidth=1)
    plt.xlabel('Numero del ciclo')
    plt.ylabel('predNum')
    plt.title('predNum vs Numero del ciclo')
    plt.xticks(numbers, fontsize=6)  
    plt.subplots_adjust(bottom=0.15) 
    plt.grid(True, alpha=0.3)
    plt.savefig('predNum_plot.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    print("Grafici individuali salvati: unitsNum_plot.png, maxLenIdx_plot.png, predNum_plot.png")

def run_lexicograph_3d(number):
    try:
        result = subprocess.run(['./lexicograph_3d', str(number)], 
                              capture_output=True, text=True, check=True)
        
        output = result.stdout.strip()
        values = output.split(',')
        
        if len(values) != 3:
            print(f"Errore: output inaspettato per numero {number}: {output}")
            return None
            
        return tuple(float(v) for v in values)
        
    except subprocess.CalledProcessError as e:
        print(f"Errore nell'esecuzione di lexicograph_3d con numero {number}")
        print(f"Stderr: {e.stderr}")
        return None
    except ValueError as e:
        print(f"Errore nella conversione dei valori per numero {number}: {output}")
        return None

def main():
    print("Eseguendo lexicograph_3d per numeri da 0 a 99...")
    
    numbers = []
    units_num = []
    max_len_idx = []
    pred_num = []
    
    for i in range(100):
        print(f"Processando numero {i}...", end=' ')
        
        result = run_lexicograph_3d(i)
        if result is not None:
            numbers.append(i)
            units_num.append(result[0])
            max_len_idx.append(result[1])
            pred_num.append(result[2])
            print(f"Risultato: {result}")
        else:
            print("Saltato a causa di errore")
    
    if not numbers:
        print("Errore: nessun dato valido ottenuto")
        return
    
    print(f"\nDati raccolti per {len(numbers)} punti")
    create_individual_plots(numbers, units_num, max_len_idx, pred_num)
    
    fig = plt.figure(figsize=(12, 9))
    ax = fig.add_subplot(111, projection='3d')
    
    scatter = ax.scatter(units_num, max_len_idx, pred_num, c=numbers, 
                        cmap='viridis', s=50, alpha=0.7)
    
    for i, (x, y, z, num) in enumerate(zip(units_num, max_len_idx, pred_num, numbers)):
        ax.text(x, y, z, str(num), fontsize=8, alpha=0.8)
    
    ax.set_xlabel('unitsNum', fontsize=12)
    ax.set_ylabel('maxLenIdx', fontsize=12)
    ax.set_zlabel('predNum', fontsize=12)
    
    ax.set_title('Grafico 3D dei risultati di lexicograph_3d\n(numeri 0-99)', 
                 fontsize=14, pad=20)
    
    cbar = plt.colorbar(scatter, ax=ax, shrink=0.5, aspect=20)
    cbar.set_label('Numero del ciclo', fontsize=12)
    
    ax.grid(True, alpha=0.3)
    
    print("\nStatistiche dei dati:")
    print(f"unitsNum - Min: {min(units_num):.2f}, Max: {max(units_num):.2f}, Media: {np.mean(units_num):.2f}")
    print(f"maxLenIdx - Min: {min(max_len_idx):.2f}, Max: {max(max_len_idx):.2f}, Media: {np.mean(max_len_idx):.2f}")
    print(f"predNum - Min: {min(pred_num):.2f}, Max: {max(pred_num):.2f}, Media: {np.mean(pred_num):.2f}")
    
    plt.savefig('lexicograph_3d_plot.png', dpi=300, bbox_inches='tight')
    print("\nGrafico salvato come 'lexicograph_3d_plot.png'")

if __name__ == "__main__":
    main()
