import Chart from "chart.js/auto";
import "chartjs-adapter-date-fns";

// Register chart.js plugins
import {
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Title,
  Tooltip,
  Legend,
  Filler,
} from "chart.js";

Chart.register(
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Title,
  Tooltip,
  Legend,
  Filler
);

const LineChart = {
  mounted() {
    this.chart = this.initChart();

    // Add resize listener for responsive charts
    this.resizeObserver = new ResizeObserver(() => {
      if (this.chart) {
        this.chart.resize();
      }
    });

    this.resizeObserver.observe(this.el);
  },

  updated() {
    if (this.chart) {
      const newData = JSON.parse(this.el.dataset.chartData);
      this.chart.data = newData;
      this.chart.update();
    }
  },

  destroyed() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }

    if (this.chart) {
      this.chart.destroy();
    }
  },

  initChart() {
    const ctx = this.el;
    const data = JSON.parse(ctx.dataset.chartData);
    const isBPChart = ctx.id === "bp-chart";

    // Set custom chart options based on chart type
    const options = {
      responsive: true,
      maintainAspectRatio: false,
      animation: {
        duration: 300, // Slightly smoother transitions
      },
      interaction: {
        mode: "index",
        intersect: false,
      },
      plugins: {
        legend: {
          position: "top",
          align: "start",
          labels: {
            usePointStyle: true,
            padding: 20,
            boxWidth: 8,
            boxHeight: 8,
            font: {
              family:
                '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
              size: 12,
            },
          },
        },
        tooltip: {
          backgroundColor: "rgba(255, 255, 255, 0.95)",
          titleColor: "#1e293b",
          bodyColor: "#475569",
          borderColor: "#e2e8f0",
          borderWidth: 1,
          cornerRadius: 8,
          padding: 12,
          boxPadding: 6,
          displayColors: true,
          usePointStyle: true,
          callbacks: {
            label: (context) => {
              let label = context.dataset.label || "";
              if (label) {
                label += ": ";
              }
              if (context.parsed.y !== null) {
                label += context.parsed.y;

                // Add units based on chart type and dataset
                if (isBPChart) {
                  if (context.dataset.label === "Heart Rate") {
                    label += " BPM";
                  } else {
                    label += " mmHg";
                  }
                }
              }
              return label;
            },
          },
        },
      },
      scales: {
        y: {
          beginAtZero: false,
          grid: {
            color: "rgba(226, 232, 240, 0.6)",
            drawBorder: false,
          },
          ticks: {
            padding: 10,
            font: {
              family:
                '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
              size: 11,
            },
            color: "#64748b",
          },
          border: {
            display: false,
          },
        },
        x: {
          grid: {
            display: false,
          },
          ticks: {
            maxRotation: 0,
            padding: 10,
            font: {
              family:
                '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
              size: 11,
            },
            color: "#64748b",
          },
          border: {
            display: false,
          },
        },
      },
      elements: {
        line: {
          tension: 0.3,
          borderWidth: 2,
        },
        point: {
          radius: 3,
          hoverRadius: 6,
          hitRadius: 10,
          borderWidth: 2,
          backgroundColor: "#fff",
        },
      },
    };

    // Add custom thresholds for BP chart
    if (isBPChart) {
      // Add reference line annotations for BP normal ranges
      options.plugins.annotation = {
        annotations: {
          systolicUpperLine: {
            type: "line",
            yMin: 140,
            yMax: 140,
            borderColor: "rgba(239, 68, 68, 0.5)",
            borderWidth: 1,
            borderDash: [6, 6],
          },
          diastolicUpperLine: {
            type: "line",
            yMin: 90,
            yMax: 90,
            borderColor: "rgba(59, 130, 246, 0.5)",
            borderWidth: 1,
            borderDash: [6, 6],
          },
        },
      };
    }

    return new Chart(ctx, {
      type: "line",
      data: data,
      options: options,
    });
  },
};

export default LineChart;
