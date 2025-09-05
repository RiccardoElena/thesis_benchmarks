import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from pathlib import Path
import os
import argparse
import subprocess
import shutil
import re


class CSVPlotter:
    def __init__(self, output_dir="grafici", input_dir=".", pattern="*.csv"):
        self.output_dir = Path(output_dir)
        self.input_dir = Path(input_dir)
        self.pattern = pattern
        self.output_dir.mkdir(exist_ok=True)
        
        # Configura lo stile dei grafici
        plt.style.use('seaborn-v0_8')
        sns.set_palette("husl")
    
    def find_csv_files(self):
        csv_files = []
        
        for file_path in self.input_dir.rglob(self.pattern):
            if file_path.is_file():
                print(f"🔍 Trovato file: {file_path}")
                csv_files.append(file_path)
        
        return sorted(csv_files)
    
    def normalize_numbers(self, path_str):
      return re.sub(r'(?<=[-_/])(\d)(?=[\D]|$)', r'0\1', path_str)
    
    def get_output_path(self, input_file_path, suffix=""):
        relative_path = input_file_path.relative_to(self.input_dir)
        normalized_path = Path(self.normalize_numbers(str(relative_path)))
        
        output_file_dir = self.output_dir / normalized_path.parent
        print(f"📂 Creazione cartella di output: {output_file_dir}")
        output_file_dir.mkdir(parents=True, exist_ok=True)
        
        base_name = normalized_path.stem
        return output_file_dir / f"{base_name}{suffix}.png"
    
    def values_from(self, zz_number):
      try:
          result = subprocess.run(['./lexicograph_3d', str(zz_number)], 
                                capture_output=True, text=True, timeout=5)
          
          if result.returncode == 0:
              return result.stdout.strip()
          else:
              print(f"⚠️ Errore nell'esecuzione di lexicograph_3d: {result.stderr}")
              return str(zz_number)
      except subprocess.TimeoutExpired:
          print(f"⚠️ Timeout nell'esecuzione di lexicograph_3d per {zz_number}")
          return str(zz_number)
      except FileNotFoundError:
          print(f"⚠️ Programma lexicograph_3d non trovato. Usando valore originale: {zz_number}")
          return str(zz_number)
      except Exception as e:
          print(f"⚠️ Errore imprevisto con lexicograph_3d: {e}")
          return str(zz_number)

    def extract_path_info(self, csv_file_path):
      path_str = str(csv_file_path)
      
      pattern = r'iff-(\d+).*?var-(\d+).*?res-(\d+)\.csv'
      
      match = re.search(pattern, path_str)
      if match:
          xx = match.group(1)
          yy = match.group(2) 
          zz = match.group(3)
          return xx, yy, zz
      else:
          print(f"⚠️ Pattern non riconosciuto per {path_str}")
          return None, None, None

    def create_title(self, csv_file_path):
      xx, yy, zz = self.extract_path_info(csv_file_path)
      
      if xx is not None and yy is not None and zz is not None:
          lexicograph_coords = self.values_from(zz)
          parts = lexicograph_coords.split(',')
          if len(parts) != 3:
              print(f"⚠️ Coordinate lessicografiche non valide per {zz}: {lexicograph_coords}")
              return csv_file_path.stem

          lex_x, lex_y, lex_z = map(int,parts)
          len_opt = ["10", "15", "20", "25", "30"]

          title = f"iff: {xx}%, var: {yy}, units: {lex_x*3 + 1}, max-len: {len_opt[lex_y]}, pred: {lex_z + 1}"
          return title
      else:

          return csv_file_path.stem
    
    def load_csv(self, file_path):
        try:
            df = pd.read_csv(file_path)
            print(f"✓ Caricato {file_path}: {df.shape[0]} righe, {df.shape[1]} colonne")
            return df
        except Exception as e:
            print(f"✗ Errore nel caricamento di {file_path}: {e}")
            return None
    
    def plot_line_chart(self, df, x_col, y_cols, title="Grafico a Linee", output_path=None):
        plt.figure(figsize=(12, 6))
        x_values = df[x_col].astype(str)
        x_positions = range(len(x_values))

        for col in y_cols:
            if col in df.columns:
              plt.plot(x_positions, df[col], marker='o', label=col, linewidth=2)
        
        plt.axhline(300000, color='orange', linestyle='--', linewidth=2, label='Time Limit')
        plt.axhline(330000, color='red', linestyle='--', linewidth=2, label='Resolution not Found or Crash')
        plt.axhline(400000, color='purple', linestyle='--', linewidth=2, label='Resolution Skipped')
        
        plt.title(title, fontsize=16, fontweight='bold')
        plt.xticks(x_positions, x_values, rotation=45)
        plt.xlabel(x_col, fontsize=12)
        plt.ylabel('Valori', fontsize=12)
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.legend(loc='upper center', bbox_to_anchor=(0.5, -0.18), ncol=2, fontsize=10, frameon=False)
    
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Salvato: {output_path}")
        
        plt.close()  
    
    def plot_bar_chart(self, df, x_col, y_col, title="Grafico a Barre", output_path=None):

        plt.figure(figsize=(10, 6))
        
        bars = plt.bar(df[x_col], df[y_col], alpha=0.8, color='skyblue', edgecolor='navy')
        

        for bar in bars:
            height = bar.get_height()
            plt.text(bar.get_x() + bar.get_width()/2., height + height*0.01,
                    f'{height:.1f}', ha='center', va='bottom')
        
        plt.title(title, fontsize=16, fontweight='bold')
        plt.xlabel(x_col, fontsize=12)
        plt.ylabel(y_col, fontsize=12)
        plt.xticks(rotation=45)
        plt.grid(True, axis='y', alpha=0.3)
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Salvato: {output_path}")
        
        plt.close()
    
    def plot_scatter(self, df, x_col, y_col, title="Grafico a Dispersione", output_path=None):
        
        plt.figure(figsize=(10, 6))
        
        plt.scatter(df[x_col], df[y_col], alpha=0.6, s=50, color='coral')
        
       
        z = np.polyfit(df[x_col], df[y_col], 1)
        p = np.poly1d(z)
        plt.plot(df[x_col], p(df[x_col]), "r--", alpha=0.8, linewidth=2)
        
        plt.title(title, fontsize=16, fontweight='bold')
        plt.xlabel(x_col, fontsize=12)
        plt.ylabel(y_col, fontsize=12)
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Salvato: {output_path}")
        
        plt.close()  
    
    def plot_histogram(self, df, col, bins=30, title="Istogramma", output_path=None):
       
        plt.figure(figsize=(10, 6))
        
        plt.hist(df[col], bins=bins, alpha=0.7, color='lightgreen', edgecolor='black')
        
        plt.title(title, fontsize=16, fontweight='bold')
        plt.xlabel(col, fontsize=12)
        plt.ylabel('Frequenza', fontsize=12)
        plt.grid(True, axis='y', alpha=0.3)
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"✓ Salvato: {output_path}")
        
        plt.close()  # Chiude la figura per liberare memoria
    
    def analyze_and_plot(self, csv_file_path):
       
        df = self.load_csv(csv_file_path)
        if df is None:
            return
        
        print(f"\n📊 Analisi di {csv_file_path}")
        print(f"Colonne: {list(df.columns)}")
        print(f"Tipi di dati:\n{df.dtypes}")
        
        
        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
        categorical_cols = df.select_dtypes(include=['object']).columns.tolist()

        base_title = self.create_title(csv_file_path)
        print(f"📋 Titolo: {base_title}")
        
        print(f"Colonne numeriche: {numeric_cols}")
        print(f"Colonne categoriche: {categorical_cols}")
        
        
        if len(numeric_cols) >= 2:
            
            output_path = self.get_output_path(csv_file_path, "_linee")
            y_cols = numeric_cols[1:4]
            self.plot_line_chart(df, numeric_cols[0], y_cols, 
                               f"{base_title}",  
                               output_path)
            
          

def main():
    
    import matplotlib
    matplotlib.use('Agg')  
    
  
    parser = argparse.ArgumentParser(description='Genera grafici da file CSV')
    parser.add_argument('--input', '-i', default='.', 
                       help='Directory di input (default: directory corrente)')
    parser.add_argument('--output', '-o', default='grafici', 
                       help='Directory di output (default: grafici)')
    parser.add_argument('--pattern', '-p', default='*.csv', 
                       help='Pattern per i nomi dei file (default: *.csv, esempio: res*.csv)')
    parser.add_argument('--clean', '-c', default=True, help='Pulisci la directory di output prima di salvare i grafici')
    
    args = parser.parse_args()
    
    print(f"🔍 Ricerca file CSV con pattern '{args.pattern}' in '{args.input}'")
    print(f"📁 Output in '{args.output}'")
    
    
    if args.clean and Path(args.output).exists():
      print(f"🧹 Pulizia della directory di output '{args.output}'")
      for file in Path(args.output).iterdir():
          try:
              if file.is_file() or file.is_symlink():
                  file.unlink()
                  print(f"  - Rimosso: {file}")
              elif file.is_dir():
                  shutil.rmtree(file)
                  print(f"  - Rimossa cartella: {file}")
          except Exception as e:
              print(f"✗ Errore nella rimozione di {file}: {e}")
    else:
        print(f"🔒 Non è stata richiesta la pulizia della directory di output '{args.output}'")
      

    plotter = CSVPlotter(output_dir=args.output, input_dir=args.input, pattern=args.pattern)
    
   
    csv_files = plotter.find_csv_files()
    
    if not csv_files:
        print(f"Nessun file CSV trovato con pattern '{args.pattern}' in '{args.input}'")
        
       
        if args.input == '.' and args.pattern == '*.csv':
            print("Creazione file CSV di esempio...")
            
            
            Path('A/B').mkdir(parents=True, exist_ok=True)
            
            # File nella root
            sample_data1 = {
                'mese': ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu'],
                'vendite': [120, 150, 180, 160, 200, 190],
                'spese': [80, 90, 100, 95, 110, 105]
            }
            pd.DataFrame(sample_data1).to_csv('A/res1.csv', index=False)
            
            # File nella sottocartella
            sample_data2 = {
                'trimestre': ['Q1', 'Q2', 'Q3', 'Q4'],
                'profitti': [1200, 1500, 1800, 1600],
                'perdite': [300, 250, 400, 350]
            }
            pd.DataFrame(sample_data2).to_csv('A/B/res2.csv', index=False)
            
            # File che non dovrebbe essere processato
            pd.DataFrame({'test': [1, 2, 3]}).to_csv('A/test.csv', index=False)
            pd.DataFrame({'test2': [4, 5, 6]}).to_csv('A/B/test2.csv', index=False)
            
            print("✓ Struttura di esempio creata in cartella 'A'")
            print("Riesegui con: python script.py --input A --pattern 'res*.csv'")
        
        return
    
    print(f"Trovati {len(csv_files)} file CSV:")
    for csv_file in csv_files:
        relative_path = csv_file.relative_to(plotter.input_dir)
        print(f"  📄 {relative_path}")
    
    print("\n" + "="*50)
    
    # Processa ogni file
    for csv_file in csv_files:
        plotter.analyze_and_plot(csv_file)
    
    print("\n🎉 Elaborazione completata!")
    print("📁 Tutti i grafici sono stati salvati in '{plotter.output_dir}' mantenendo la struttura delle cartelle")
    
    # Mostra la struttura finale
    print("\n📂 Struttura di output:")
    for root, dirs, files in os.walk(plotter.output_dir):
        level = root.replace(str(plotter.output_dir), '').count(os.sep)
        indent = ' ' * 2 * level
        print(f"{indent}{os.path.basename(root)}/")
        subindent = ' ' * 2 * (level + 1)
        for file in files:
            print(f"{subindent}{file}")

if __name__ == "__main__":
    main()