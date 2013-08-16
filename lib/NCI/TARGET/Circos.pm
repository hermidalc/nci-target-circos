package NCI::TARGET::Circos;

use Dancer qw(:syntax);
use Dancer::Plugin::Thumbnail;
use File::Basename qw(basename fileparse);
use Image::Size qw(imgsize);

our $VERSION = '0.1';

# defaults
my $default_num_display_cols = 3;
my $default_thumb_w = 500;
my $default_overlay_thumb_w = 800;
my $default_legend_thumb_w = 100;
my $lightbox_thumb_w = 700;

get '/' => sub {
    template 'index';
};

get '/:disease' => sub {
    my (@image_files, $legend_image_file, @circos_types, 
        @target_case_ids, @cmp_types, %num_cmp_type_images);
    my $disease_image_dir = config->{'public'} . '/' . param('disease') . '/images';
    for my $image_file_name (<$disease_image_dir/*.png>) {
        if ($image_file_name !~ /legend\..+?$/i) {
            push @image_files, basename($image_file_name);
            my $image_file_basename = fileparse($image_file_name, qr/\.[^.]*/);
            my ($circos_type, $target_case_id, $disease_state_cmp_type) = 
                $image_file_basename =~ /^(.+?)_(.+?)_(.+?)$/;
            push @circos_types, $circos_type;
            push @target_case_ids, $target_case_id;
            push @cmp_types, $disease_state_cmp_type;
            $num_cmp_type_images{$disease_state_cmp_type}++;
        }
        else {
            $legend_image_file = basename($image_file_name);
        }
    }
    my @unique_cmp_types = sort keys %num_cmp_type_images;
    my ($legend_w, $legend_h) = imgsize("$disease_image_dir/$legend_image_file");
    template 'circos' => {
        'page_title' => 'NCI TARGET ' . param('disease') . ' CGI Circos Plots',
        'disease' => param('disease'),
        'circos_types' => \@circos_types,
        'target_case_ids' => \@target_case_ids,
        'cmp_types' => \@cmp_types,
        'unique_cmp_types' => \@unique_cmp_types,
        'num_cmp_type_images' => \%num_cmp_type_images,
        'num_display_cols' => 
            param('arrange_by') 
                ? scalar(@unique_cmp_types) 
                : ( param('cols') || $default_num_display_cols ),
        'image_files' => \@image_files,
        'legend_image_file' => $legend_image_file,
        'arrange_by' => param('arrange_by'),
        'thumb_w' => param('tsize') || $default_thumb_w,
        'legend_thumb_w' => $default_legend_thumb_w,
        'overlay_thumb_w' => $default_overlay_thumb_w,
        'legend_w' => $legend_w,
        'legend_h' => $legend_h,
        'lightbox_thumb_w' => $lightbox_thumb_w,
    };
};

get '/:disease/thumb/:w/:image' => sub {
    resize config->{'public'} . '/' . param('disease') . '/images/' . param('image') => {
        w => param('w') || $default_thumb_w,
    };
};

get '/:disease/thumb/legend/:w/:image' => sub {
    resize config->{'public'} . '/' . param('disease') . '/images/' . param('image') => {
        w => param('w') || $default_legend_thumb_w,
    };
};

get '/:disease/overlay' => sub {
    my $image_file_0_basename = fileparse(param('img0'), qr/\.[^.]*/);
    my (undef, $target_case_id_0, $disease_state_cmp_type_0) = 
        $image_file_0_basename =~ /^(.+?)_(.+?)_(.+?)$/;
    my $image_file_1_basename = fileparse(param('img1'), qr/\.[^.]*/);
    my (undef, $target_case_id_1, $disease_state_cmp_type_1) = 
        $image_file_1_basename =~ /^(.+?)_(.+?)_(.+?)$/;
    template 'circos_overlay' => {
        'disease' => param('disease'),
        'case_id' => $target_case_id_0,
        'thumb_w' => param('tsize') || $default_overlay_thumb_w,
        'image_file_0' => param('img0'),
        'image_file_1' => param('img1'),
        'label_file_0' => $disease_state_cmp_type_0,
        'label_file_1' => $disease_state_cmp_type_1,
    }, {
        layout => 'overlay',
    };
};

true;
