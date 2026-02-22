#!/usr/bin/env python3
"""
Generate scatter plots or line charts using matplotlib.
Accepts JSON input with data values and optional x,y coordinates.
"""

import json
import sys
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from pathlib import Path


def generate_scatter_plot(x_coords, y_coords, output_path, title="Scatter Plot"):
    """
    Generate a scatter plot from x,y coordinates.
    
    Args:
        x_coords: List of x coordinate values
        y_coords: List of y coordinate values
        output_path: Path where to save the PNG file
        title: Chart title
    """
    # Ensure output directory exists
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Create figure and axis with white background
    fig, ax = plt.subplots(figsize=(10.67, 8), dpi=75, facecolor='white')
    ax.set_facecolor('white')
    
    # Plot scatter points
    ax.scatter(x_coords, y_coords, color='#0066CC', s=30, alpha=0.7, label='Messungen', zorder=3)
    
    # Calculate and plot trend ellipse (2D linear regression)
    if len(x_coords) > 2:
        # Simple 2D trend: fit a line to the data
        import numpy as np
        x_array = np.array(x_coords)
        y_array = np.array(y_coords)
        
        # Fit polynomial (degree 1 = linear)
        coeffs = np.polyfit(x_array, y_array, 1)
        poly = np.poly1d(coeffs)
        
        # Generate trend line
        x_trend = np.linspace(np.min(x_array), np.max(x_array), 100)
        y_trend = poly(x_trend)
        ax.plot(x_trend, y_trend, color='#CC0000', linewidth=2, label='Trend', zorder=2)
    
    # Styling
    ax.set_xlabel('X-Koordinate', fontsize=11, fontweight='bold')
    ax.set_ylabel('Y-Koordinate', fontsize=11, fontweight='bold')
    ax.set_title(title, fontsize=13, fontweight='bold', pad=15)
    
    # Grid
    ax.grid(True, color='#E0E0E0', linestyle='-', linewidth=0.5, alpha=0.7, zorder=0)
    
    # Legend
    ax.legend(loc='best', fontsize=10, framealpha=0.95)
    
    # Tight layout
    plt.tight_layout()
    
    # Save as PNG
    plt.savefig(str(output_file), format='png', dpi=75, facecolor='white', edgecolor='none')
    plt.close()


def generate_line_chart(measurements, trendline, output_path, title="Measurement Analysis"):
    """
    Generate a line chart with trend line.
    
    Args:
        measurements: List of measurement values
        trendline: List of trendline values (same length as measurements)
        output_path: Path where to save the PNG file
        title: Chart title
    """
    # Ensure output directory exists
    output_file = Path(output_path)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Create figure and axis with white background
    fig, ax = plt.subplots(figsize=(10.67, 8), dpi=75, facecolor='white')
    ax.set_facecolor('white')
    
    # X-axis: measurement indices
    x = list(range(len(measurements)))
    
    # Plot measurement points as blue dots
    ax.scatter(x, measurements, color='#0066CC', s=30, alpha=0.7, label='Messungen', zorder=3)
    
    # Plot trend line
    ax.plot(x, trendline, color='#CC0000', linewidth=2, label='Trend', zorder=2)
    
    # Styling
    ax.set_xlabel('Messnummer', fontsize=11, fontweight='bold')
    ax.set_ylabel('Messwert', fontsize=11, fontweight='bold')
    ax.set_title(title, fontsize=13, fontweight='bold', pad=15)
    
    # Grid
    ax.grid(True, color='#E0E0E0', linestyle='-', linewidth=0.5, alpha=0.7, zorder=0)
    
    # Legend
    ax.legend(loc='best', fontsize=10, framealpha=0.95)
    
    # Tight layout
    plt.tight_layout()
    
    # Save as PNG
    plt.savefig(str(output_file), format='png', dpi=75, facecolor='white', edgecolor='none')
    plt.close()


def main():
    """Main entry point - read JSON from stdin and generate chart."""
    try:
        # Read JSON from stdin
        input_data = json.loads(sys.stdin.read())
        
        output_path = input_data.get('output_path', 'chart.png')
        title = input_data.get('title', 'Analysis')
        
        # Check if this is a scatter plot (has x,y coordinates) or line chart
        if 'coordinateX' in input_data and 'coordinateY' in input_data:
            x_coords = input_data.get('coordinateX', [])
            y_coords = input_data.get('coordinateY', [])
            
            if not x_coords or not y_coords:
                print("Error: coordinateX and coordinateY arrays are required", file=sys.stderr)
                sys.exit(1)
            
            if len(x_coords) != len(y_coords):
                print("Error: coordinateX and coordinateY must have the same length", file=sys.stderr)
                sys.exit(1)
            
            generate_scatter_plot(x_coords, y_coords, output_path, title)
            print(f"Scatter plot saved to {output_path}")
        else:
            # Line chart with measurements and trend
            measurements = input_data.get('measurements', [])
            trendline = input_data.get('trendline', [])
            
            if not measurements or not trendline:
                print("Error: measurements and trendline arrays are required", file=sys.stderr)
                sys.exit(1)
            
            if len(measurements) != len(trendline):
                print("Error: measurements and trendline must have the same length", file=sys.stderr)
                sys.exit(1)
            
            generate_line_chart(measurements, trendline, output_path, title)
            print(f"Line chart saved to {output_path}")
        
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error generating chart: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()

