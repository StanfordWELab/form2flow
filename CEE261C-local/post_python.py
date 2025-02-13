import numpy as np
import matplotlib.pyplot as plt
from scipy import stats, signal, optimize
import statsmodels.api as sm
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.pdfgen import canvas
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Image, PageBreak

# Constants for theoretical calculations - these to change depending on user data/terrain category
u_star = 1.08  # Friction velocity
kappa = 0.41   # von Kármán constant
z0 = 0.27      # Roughness length

def read_probe_data(data_file):
    """Read the probe data file and extract the last saved timestep."""
    with open(data_file, 'r') as f:
        lines = f.readlines()

    data = []
    for line in lines:
        if line.startswith("#"):
            continue
        values = list(map(float, line.split()))
        data.append(values)

    data = np.array(data)
    last_time_step = data[-1, 3:]  # Extract last row, skipping first 3 columns
    return last_time_step

def read_probe_coordinates(coord_file):
    """Read the probe coordinates and extract the heights (Z values)."""
    with open(coord_file, 'r') as f:
        lines = f.readlines()

    z_values = []
    for line in lines:
        if line.startswith("#"):
            continue
        values = list(map(float, line.split()))
        z_values.append(values[3])  # Z is the fourth column

    return np.array(z_values)

def read_velocity_time_series(time_series_file):
    """Read the velocity time series data, excluding the first 10000 timesteps. - just to avoid the pressure waves at the start"""
    time = []
    velocity = []

    with open(time_series_file, 'r') as f:
        lines = f.readlines()
    
    for line in lines:
        if line.startswith("#"):
            continue
        values = list(map(float, line.split()))
        time.append(values[1])  # Time is the second column
        velocity.append(values[3])  # Velocity is the fourth column

    # Convert to numpy arrays and slice to remove the first 10000 timesteps
    time = np.array(time)[10000:]
    velocity = np.array(velocity)[10000:]

    return time, velocity

def LengthScale(uInst, meanU, time, show_plot=False):
    """Compute the length scale of the flow using the exponential fit method."""
    meanTemp = np.mean(uInst)  # compute the mean velocity
    uPrime = uInst - meanTemp  # subtract the mean velocity from the instantaneous velocity
    func = lambda x, a: np.exp(-x/a)  # define theoretical exponential decay function
    time -= time[0]  # shift time to start at zero

    R_u = sm.tsa.stattools.acf(uPrime, nlags=len(time)-1, fft=True)  # compute autocorrelation function
    R_uFit, _ = optimize.curve_fit(func, time, R_u, p0=1, bounds=(0, np.inf))  # fit the exponential decay function to the autocorrelation function
    t_scale = R_uFit[0]  # extract the length scale from the fit
    Lx = t_scale * meanU  # compute the length scale of the flow
    if show_plot:
        plt.figure()
        plt.plot(time, R_u, label='Autocorrelation')
        plt.plot(time, func(time, *R_uFit), label='Exponential fit')
        plt.xlabel('Time')
        plt.ylabel('Autocorrelation')
        plt.legend()

    return Lx

def compute_theoretical_values(z_values):
    """Compute theoretical proviles for turbulence intensity and velocity profile."""
    log_term = np.log((z_values + z0) / z0)
    
    U_mag = (u_star / kappa) * log_term
    I_u = 1 / log_term
    I_v = 0.88 * I_u
    I_w = 0.55 * I_u

    return I_u, I_v, I_w, U_mag

def plot_subplots(z_values, data_files, x_labels, filename=None):
    """Create subplots comparing simulation data with theoretical profiles"""
    
    # Set font properties for larger text
    plt.rcParams.update({'font.size': 14, 'font.weight': 'bold'})
    
    fig, axes = plt.subplots(1, 4, figsize=(22, 7))  # Adjust figure size for larger text and better spacing

    # Compute theoretical values
    I_u, I_v, I_w, U_mag = compute_theoretical_values(z_values)
    theoretical_values = [I_u, I_v, I_w, U_mag]

    for i, (data_file, x_label, theory) in enumerate(zip(data_files, x_labels, theoretical_values)):
        last_timestep = read_probe_data(data_file)  # Read the simulation data
        ax = axes[i]

        # Plot
        ax.plot(last_timestep, z_values, 'o-', label="Simulation Data", color='tab:blue', markersize=6, linewidth=2)
        ax.plot(theory, z_values, 'r--', label="Theoretical", linewidth=2)  # Theoretical values

        ax.set_xlabel(x_label, fontsize=16)
        ax.set_ylabel('Height (Z)', fontsize=16)

        # Set title for each subplot
        ax.set_title(f"Comparison of {x_label}", fontsize=18, weight='bold')

        ax.grid(True, which='both', linestyle='--', linewidth=0.5)
        ax.legend(fontsize=14)
        
        ax.tick_params(axis='both', which='major', labelsize=14)
        ax.tick_params(axis='both', which='minor', labelsize=12)

    plt.tight_layout(pad=3.0)  # Increase space between subplots

    if filename:
        plt.savefig(filename, dpi=300) 
        print(f"Figure saved as {filename}")
    else:
        plt.show()

def generate_pdf_with_reportlab(pdf_filename, z_values, data_files, x_labels, time_series_file):
    """Generate a PDF report including text, equations, and plots using ReportLab."""
    # Create a PDF document
    doc = SimpleDocTemplate(pdf_filename, pagesize=letter)
    
    # Create the content list
    content = []
    styles = getSampleStyleSheet()
    
    # Title page
    title = Paragraph("ABL (empty domain) simulation report", styles['Title'])
    content.append(title)
    content.append(Paragraph("<br/>This report compares simulation data with theoretical profiles for turbulence intensity "
                             "(I_u, I_v, I_w), mean velocity profile (U_mag), and power spectra density.", styles['Normal']))
    content.append(Paragraph("<br/><b>Theoretical Profile (log-law)</b><br/><i>U(z) = (u^* / kappa) * log((z + z_0) / z_0)</i>", styles['Normal']))
    content.append(Paragraph("<br/><b>Turbulence Intensity:</b><br/>I_u = 1 / log((z + z_0) / z_0)<br/>I_v = 0.88 * I_u<br/>I_w = 0.55 * I_u", styles['Normal']))
    
    # Page Break
    content.append(Paragraph("<br/><br/><b>Parameters used in calculations:</b>", styles['Normal']))
    content.append(Paragraph(f"Friction velocity (u*): {u_star}<br/>von Kármán constant (κ): {kappa}<br/>Roughness length (z_0): {z0}", styles['Normal']))
    
    # Read velocity time series
    time, velocity = read_velocity_time_series(time_series_file)
    
    # Compute the length scale
    Lx = LengthScale(velocity, np.mean(velocity), time, show_plot=False)
    content.append(Paragraph(f"<br/><b>Length Scale (Lx):</b> {Lx:.2f}", styles['Normal']))

    # Compute Welch Power Spectral Density
    fsamp = 1 / 0.05  # Sampling frequency - Change according to simulation timestep
    N = len(velocity)
    f, Euu = signal.welch(velocity, fs=fsamp, axis=0, nperseg=N//4, scaling='density', detrend='constant')

    # Non-dimensionalize frequency using Von Kármán scaling
    f = f * Lx / np.mean(velocity)
    sigma2_u = np.var(velocity, axis=0)
    Euu = f * Euu / sigma2_u

    # Von Kármán Spectrum (Su)
    g = 4 #0.5
    Su = g * f / (1 + 70.8 * (f)**2)**(5/6)

    # Plot Welch spectrum and Von Kármán spectrum
    plt.figure(figsize=(12, 8))

    # Plot the Welch PSD and Von Kármán Spectrum
    plt.loglog(f, Euu, label="Welch PSD", color='b', linewidth=2)
    plt.loglog(f, Su, label="Von Kármán Spectrum", color='r', linestyle='--', linewidth=2)

    # Set labels and title with larger font sizes
    plt.xlabel('$f\ Lu_x/U$ ', fontsize=24, weight='bold')
    plt.ylabel('$f\  S_u/\sigma^2_{u}$', fontsize=24, weight='bold')
    # plt.title('Welch Power Spectral Density vs Theoretical Von Kármán Spectrum', fontsize=24, weight='bold')

    # Limit the x and y axes (adjust the limits as needed)
    plt.xlim(0.001, 2)  # Limit the x-axis (frequency range)
    plt.ylim(1e-6, 1e1)  # Limit the y-axis (Power Spectral Density range)

    # Customize tick labels for better readability
    plt.xticks(fontsize=24)
    plt.yticks(fontsize=24)

    # Add legend with larger font size
    plt.legend(fontsize=24)

    # Improve layout for better spacing
    plt.tight_layout()

    # Save the plot with higher resolution
    plt.savefig('welch_vs_von_karman.png', dpi=300)

    # Generate and save plots
    plot_subplots(z_values, data_files, x_labels, filename="subplots.png")

    # Add plot image to PDF
    content.append(Paragraph("<br/><br/><b>Comparison of Simulation and Theoretical Profiles</b>", styles['Normal']))
    content.append(Image("subplots.png", width=540, height=180))

    # Add page break before adding the plot image to PDF
    content.append(PageBreak())


    # Add plot image to PDF
    content.append(Paragraph("<br/><br/><b>Power Spectral Density Comparison</b>", styles['Normal']))
    content.append(Image("welch_vs_von_karman.png", width=360, height=240))
    
    # Build PDF
    doc.build(content)
    print(f"PDF saved as {pdf_filename}")

# File paths
data_files = [
    "./probes/building_loc.comp(rms(u),0)_d_avg(mag(u))",
    "./probes/building_loc.comp(rms(u),1)_d_avg(mag(u))",
    "./probes/building_loc.comp(rms(u),2)_d_avg(mag(u))",
    "./probes/building_loc.avg(mag(u))"
]

coord_file = "./probes/building_loc.README"
time_series_file = "./probes/building_height_timeseries.mag(u)"

# Read coordinates (Z values)
z_values = read_probe_coordinates(coord_file)

# x-axis labels
x_labels = ['I_u', 'I_v', 'I_w', 'U_mag']

# Generate PDF
generate_pdf_with_reportlab("ABL_report.pdf", z_values, data_files, x_labels, time_series_file)
